const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');

admin.initializeApp();  // Initialize Firebase Admin

const db = admin.firestore();  // Get Firestore reference

// Enable CORS with the default options (allows all origins)
const corsHandler = cors({ origin: true });

// Endpoint 1: Verify Magic Word and Return Magic Hash
exports.verifyMagicWord = functions.region('europe-west3').https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      const { magicWord } = req.body;
      if (!magicWord) {
        res.status(400).send('Missing magicWord in request body');
        return;
      }

      // Get the magic word from Firestore
      const magicWordDoc = await db.collection('secrets').doc('magic_word').get();
      if (!magicWordDoc.exists) {
        res.status(404).send('Magic word not found in database');
        return;
      }

      const magicWordValue = magicWordDoc.data().value;

      // Compare provided magic word with stored value
      console.warn("In DB:", magicWordValue);
      console.warn("In params:", magicWord);

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

// Endpoint 2: Publish Poem if Magic Hash Matches
exports.publishPoem = functions.region('europe-west3').https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      const { text, magicHash } = req.body;
      if (!text || !magicHash) {
        res.status(400).send('Missing text or magicHash in request body');
        return;
      }

      // Get the magic hash from Firestore
      const magicHashDoc = await db.collection('secrets').doc('magic_hash').get();
      if (!magicHashDoc.exists) {
        res.status(404).send('Magic hash not found in database');
        return;
      }

      const magicHashValue = magicHashDoc.data().value;

      // Compare provided magic hash with stored value
      if (magicHash !== magicHashValue) {
        res.status(403).send('Invalid magic hash');
        return;
      }

      // Add the poem to Firestore if magic hash is valid
      await db.collection('poems').add({
        text: text,
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        heartCount: 0
      });

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

    const poemId = req.body.poemId;

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

    const poemId = req.body.poemId;

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