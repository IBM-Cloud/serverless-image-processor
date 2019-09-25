const COS = require('ibm-cos-sdk');
const gm = require('gm').subClass({ imageMagick: true });
const fs = require('fs');

async function thumbnail(imageData) {
  return new Promise((resolve, reject) => {
    gm(imageData).resize(160).toBuffer('jpg', (err, buffer) => {
      if (err) {
        console.log(err);
        reject(err);
      } else {
        resolve(buffer);
      }
    });
  });
}

function thumbnailName(fileKey) {
  const lastDot = (fileKey+"").lastIndexOf('.');
  if (lastDot === -1) {
    return `${fileKey}.jpg`;
  } else {
    return `${fileKey.substring(0, lastDot)}.jpg`;
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

    // generate a thumbnail
    console.log('Generating thumbnail...');
    const thumbnailData = await thumbnail(imageData.Body);

    // upload the thumbnail to COS
    const thumbnailKey = `thumbnails/${thumbnailName(event.key)}`;
    console.log(`Uploading ${event.bucket}/${thumbnailKey}...`);
    const thumbnailObject = await cos.putObject({
      Bucket: event.bucket,
      Key: thumbnailKey,
      Body: thumbnailData,
      ContentType: 'image/jpg',
    }).promise();

    console.log('[OK] Thumbnail uploaded', thumbnailObject);

    return event;
  } catch (err) {
    console.log('[KO]', err);
    throw err;
  }
}
