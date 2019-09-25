function main(event) {
  if (event.key.startsWith('thumbnails/') || event.key.startsWith('metadata/')) {
    throw new Error('Ignoring event on thumbnail or metadata');
  }

  const key = event.key.toLowerCase();
  if (!(
    key.endsWith('.jpg') ||
    key.endsWith('.jpeg') ||
    key.endsWith('.png') ||
    key.endsWith('.gif')
  )) {
    throw new Error('Ignoring file extension (only jpg, jpeg, png, gif are supported)');
  }

  return event;
}
