

const admin = require("firebase-admin");

const serviceAccount = require("./service_account_key.json");
const { getFirestore } = require('firebase-admin/firestore');

const app = admin.initializeApp({
    credential: admin.credential.cert('service_account_key.json'),
    
  },'whatever');


const db = getFirestore(app, 'staging');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "poem-app-2c3c7",
  databaseURL: 'staging'
});

poemId = 123

db.collection('poems').where('id', '==', parseInt(poemId, 10)).limit(1).get().then((querySnapshot) => console.log(querySnapshot.docs[0].ref.collection('comments')));