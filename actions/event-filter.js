function main(event) {
  if (event.key.startsWith('thumbnails/') || event.key.startsWith('metadata/')) {
    throw new Error('Ignoring event');
  }

  return event;
}
