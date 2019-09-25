const COS = require('ibm-cos-sdk');

function thumbnailName(fileKey) {
  const lastDot = (fileKey+"").lastIndexOf('.');
  if (lastDot === -1) {
    return `${fileKey}.jpg`;
  } else {
    return `${fileKey.substring(0, lastDot)}.jpg`;
  }
}

function metadataName(fileKey) {
  const lastDot = (fileKey+"").lastIndexOf('.');
  if (lastDot === -1) {
    return `${fileKey}-vr.json`;
  } else {
    return `${fileKey.substring(0, lastDot)}-vr.json`;
  }
}

async function main(event) {
  // remove the thumbnail for the given image
  try {
    const config = {
      endpoint: event.endpoint,
      apiKeyId: event.cosApiKey,
      serviceInstanceId: event.cosInstanceId,
    };
    const cos = new COS.S3(config);

    const keysToDelete = [
      `thumbnails/${thumbnailName(event.key)}`,
      `metadata/${metadataName(event.key)}`,
    ]
    keysToDelete.forEach((key) => {
      console.log(`Deleting ${event.bucket}/${key}...`);
      await cos.deleteObject({
        Bucket: event.bucket,
        Key: key,
      }).promise();
    });
    console.log('[OK] Delete complete');

    return event;
  } catch (err) {
    console.log('[KO]', err);
    throw err;
  }
}