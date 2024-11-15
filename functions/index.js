const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const { Firestore, Timestamp } = require('@google-cloud/firestore');


admin.initializeApp();  // Initialize Firebase Admin

// Enable CORS with the default options (allows all origins)
const corsHandler = cors({ origin: true });

const NOTIFICATION_THRESHOLD = 15 * 60 * 1000;


const allowedDatabases = ['(default)', 'staging'];

function getFirstNCodePoints(str, n) {
  return Array.from(str).slice(0, n).join('');
}

function getFirestoreForDatabase(databaseId) {
  databaseId = (databaseId || 'default').toLowerCase()
  databaseId = databaseId === 'default' ? '(default)' : databaseId

  if (!allowedDatabases.includes(databaseId)) {
    throw new Error('Invalid databaseId');
  }

  return new Firestore({
    projectId: process.env.GCLOUD_PROJECT,
    databaseId: databaseId,
  });
}

// Endpoint 1: Verify Magic Word and Return Magic Hash
exports.verifyMagicWord = functions.region('europe-west3').https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      const { magicWord, databaseId } = req.body;
      if (!magicWord) {
        res.status(400).send('Missing magicWord in request body');
        return;
      }

      db = getFirestoreForDatabase(databaseId);

      // Get the magic word from Firestore
      const magicWordDoc = await db.collection('secrets').doc('magic_word').get();
      if (!magicWordDoc.exists) {
        res.status(404).send('Magic word not found in database');
        return;
      }

      const magicWordValue = magicWordDoc.data().value;

  

      if (magicWord !== magicWordValue) {
        res.status(403).send('Incorrect magic word');
        return;
      }

      // If the magic word matches, return the magic hash
      const magicHashDoc = await db.collection('secrets').doc('magic_hash').get();
      if (!magicHashDoc.exists) {
        res.status(404).send('Magic hash not found in database');
        return;
      }

      const magicHashValue = magicHashDoc.data().value;
      res.status(200).send({ magicHash: magicHashValue });

    } catch (error) {
      console.error('Error verifying magic word:', error);
      res.status(500).send('Internal Server Error');
    }
  });
});

exports.addComment = functions.region('europe-west3').https.onRequest((req, res) => {
    // Handle CORS
    corsHandler(req, res, async () => {
      // Only allow POST requests
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method Not Allowed' });
        return;
      }

      try {
        const { comment, poemId, databaseId } = req.body;

        db = getFirestoreForDatabase(databaseId);

        // Validate request body
        if (!comment || !poemId) {
          res.status(400).json({ error: 'Missing comment or poemId in request body' });
          return;
        }

        // Generate a unique ID for the comment
        const commentId = uuidv4();
        comment.id = commentId;
        comment.createdAt = admin.firestore.FieldValue.serverTimestamp().toString();
        comment.updateAt = comment.createdAt;

        console.log("POEM ID", parseInt(poemId, 10));

        // Reference to the specific poem document
        const poemRef = db.collection('poems').where('id', '==', parseInt(poemId, 10)).limit(1);

        // Check if the poem exists
        const poemSnapshot = await poemRef.get();
        if (poemSnapshot.empty) {
          res.status(404).json({ error: 'Poem not found' });
          return;
        }

        const poemDoc = poemSnapshot.docs[0].ref;

        await poemDoc.update({
           comments: admin.firestore.FieldValue.arrayUnion(comment)
        });

        // Respond with success
        res.status(200).json({ message: 'Comment added successfully', commentId });
      } catch (error) {
        console.error('Error adding comment:', error);
        res.status(500).json({ error: 'Internal Server Error' });
      }
    });
  });

// Endpoint 2: Publish Poem if Magic Hash Matches
exports.publishPoem = functions.region('europe-west3').https.onRequest((req, res) => {
  const fcm = admin.messaging();
  console.log("Publish poem executing");
  corsHandler(req, res, async () => {
    console.log("Inside the cors")
    try {
      // Only allow POST requests
      if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      //console.log("Request body", req.body);

      // Get the text and magicHash from the request body
      const { text, magicHash, databaseId, publishedAt } = req.body;

      // Check if required parameters are present
      if (!text || !magicHash) {
        res.status(400).send('Missing text or magicHash in request body');
        return;
      }

      db = getFirestoreForDatabase(databaseId);

      console.log("Checking ig magic hash exist in db.")

      // Fetch the stored magic hash from Firestore
      const magicHashDoc = await db.collection('secrets').doc('magic_hash').get();
      if (!magicHashDoc.exists) {
        res.status(404).send('Magic hash not found in database');
        return;
      }

      console.log("Receiving magic hash");

      const magicHashValue = magicHashDoc.data().value;

      // Verify the provided magic hash with the stored value
      if (magicHash !== magicHashValue) {
        res.status(403).send('Invalid magic hash');
        return;
      }

      const counterRef = db.collection('configs').doc('poemCounter');

      // Use transaction to atomically increment the counter
      const newDocID = await db.runTransaction(async (transaction) => {
        const counterDoc = await transaction.get(counterRef);
        let currentID = counterDoc.exists ? counterDoc.data().count : 0;
    
        // Increment the counter
        const newID = currentID + 1;
        transaction.update(counterRef, { count: newID });
        return newID;
      });

      publishedTimestamp = null;

      if (publishedAt) {
        const [day, month, year] = publishedAt.split('/');
        const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
        publishedTimestamp = Timestamp.fromDate(date);
      }

      console.log("Attempting db.collection.add");

      cleanText = text.replace(/[\x00-\x1F\x7F-\x9F]/g, '');

      // Add the poem to Firestore
      await db.collection('poems').add({
        id: newDocID,
        text: cleanText,
        publishedAt: (publishedAt && publishedTimestamp) || admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        heartCount: 0,
        searchValues: [...new Set(
          cleanText.trim()
            .split(/\s+/)
            .map(e => e.toLowerCase())
            .flatMap(d => {
              const len = Array.from(d).length;
              if (len < 5) {
                return [d];
              } else {
                return [
                  d,
                  getFirstNCodePoints(d, 5),
                  getFirstNCodePoints(d, 6),
                  getFirstNCodePoints(d, 7),
                ];
              }
            })
            .filter(e => Array.from(e).length > 2)
        )]
      });

      if (databaseId !== '(default)') {
        res.status(200).send('Poem published successfully');
        return;
      }

      console.log("Pushing notification...")

      // Check for throttling by fetching the last notification time from Firestore
      const throttleDocRef = db.collection('configs').doc('notificationThrottle');
      const throttleDoc = await throttleDocRef.get();
      const now = Date.now();
      let lastNotificationTime = throttleDoc.exists ? throttleDoc.data().lastSent : 0;
      const title_ = 'Nowy wiersz został opublikowany!';
      const body_ = `"${text.substring(0, 20)}..."`

      // Ensure at least 15 minutes have passed since the last notification
      if (now - lastNotificationTime >= NOTIFICATION_THRESHOLD) {
        // Build the notification payload for Android and iOS
        const message = {
          notification: {
            title: title_,
            body: body_, // Shortened text for notification
          },
          topic: 'all', // Send to all users subscribed to the "all" topic
          android: {
            priority: 'high',
            notification: {
              sound: 'default', // Default notification sound
              channelId: 'poem_channel', // Notification channel for Android
            },
          },
          apns: {
            headers: {
              'apns-priority': '10', // Immediate priority for iOS notifications
            },
            payload: {
              aps: {
                alert: {
                  title: title_,
                  body: body_, // Shortened text for iOS
                },
                sound: 'default', // Default sound for iOS
              },
            },
          },
        };

        // Send the notification via FCM
        try {
          await fcm.send(message);
          console.log('Notification sent successfully.');

          // Update the last notification time to throttle future notifications
          await throttleDocRef.set({ lastSent: now });
        } catch (error) {
          console.error('Error sending notification:', error);
        }
      } else {
        console.log('Notification throttled to avoid spamming users.');
      }

      // Respond with success if the poem is published
      res.status(200).send('Poem published successfully');
      
    } catch (error) {
      console.error('Error publishing poem:', error);
      res.status(500).send('Internal Server Error');
    }
  });
});

exports.decreaseHeartCount = functions.region('europe-west3').https.onRequest((req, res) => {
  // Handle CORS
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const { poemId, databaseId } = req.body;
    
    db = getFirestoreForDatabase(databaseId);

    if (!poemId) {
      return res.status(400).send('Missing poemId in request body.');
    }

    try {
      // Run a transaction to safely decrement the heart count
      await db.runTransaction(async (transaction) => {
        const poemRef = db.collection('poems').doc(poemId);
        const poemDoc = await transaction.get(poemRef);

        if (!poemDoc.exists) {
          return res.status(404).send('The specified poem does not exist.');
        }

        const currentHeartCount = poemDoc.data().heartCount || 0;

        if (currentHeartCount <= 0) {
          return res.status(400).send('Heart count cannot be less than zero.');
        }

        // Decrement the heart count by 1
        transaction.update(poemRef, {
          heartCount: currentHeartCount - 1
        });
      });

      return res.status(200).send({ message: 'Heart count successfully decremented.' });
    } catch (error) {
      console.error('Error decreasing heart count:', error);
      return res.status(500).send('An error occurred while decreasing heart count.');
    }
  });
});


exports.increaseHeartCount = functions.region('europe-west3').https.onRequest((req, res) => {
  // Handle CORS
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const { poemId, databaseId } = req.body;
    
    db = getFirestoreForDatabase(databaseId);

    if (!poemId) {
      return res.status(400).send('Missing poemId in request body.');
    }

    try {
      // Run a transaction to safely increment the heart count
      await db.runTransaction(async (transaction) => {
        const poemRef = db.collection('poems').doc(poemId);
        const poemDoc = await transaction.get(poemRef);

        if (!poemDoc.exists) {
          return res.status(404).send('The specified poem does not exist.');
        }

        const currentHeartCount = poemDoc.data().heartCount || 0;

        // Increment the heart count by 1
        transaction.update(poemRef, {
          heartCount: currentHeartCount + 1
        });
      });

      return res.status(200).send({ message: 'Heart count successfully incremented.' });
    } catch (error) {
      console.error('Error increasing heart count:', error);
      return res.status(500).send('An error occurred while increasing heart count.');
    }
  });
});