const COS = require('ibm-cos-sdk');
const VisualRecognitionV3 = require('ibm-watson/visual-recognition/v3');
const fs = require('fs');

function metadataName(fileKey) {
  const lastDot = (fileKey+"").lastIndexOf('.');
  if (lastDot === -1) {
    return `${fileKey}-vr.json`;
  } else {
    return `${fileKey.substring(0, lastDot)}-vr.json`;
  }
}

async function main(event) {
  try {
    const config = {
      endpoint: event.endpoint,
      apiKeyId: event.cosApiKey,
      serviceInstanceId: event.cosInstanceId,
    };
    const cos = new COS.S3(config);

    // get the image from COS
    console.log(`Downloading ${event.bucket}/${event.key} from COS...`);
    const imageData = await cos.getObject({
      Bucket: event.bucket,
      Key: event.key,
    }).promise();
    fs.writeFileSync('./image.jpg', imageData.Body);

    var visualRecognition = new VisualRecognitionV3({
      url: event.vrUrl,
      version: '2018-03-19',
      iam_apikey: event.vrApiKey,
    });
    var params = {
      images_file: fs.createReadStream('./image.jpg')
    };
    
    // call visual recognition
    console.log('Analyzing image...');
    const metadata = await visualRecognition.classify(params);

    // store the metadata
    const metadataKey = `metadata/${metadataName(event.key)}`;
    console.log(`Uploading ${event.bucket}/${metadataKey}...`);
    const metadataObject = await cos.putObject({
      Bucket: event.bucket,
      Key: metadataKey,
      Body: JSON.stringify(metadata, null, 2),
      ContentType: 'application/json',
    }).promise();

    console.log('[OK] Visual recognition complete', JSON.stringify(metadata));

    return event;
  } catch (err) {
    console.log('[KO]', err);
    throw err;
  }
}
