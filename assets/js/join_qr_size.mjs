// Size of the QR code on the presenter join screen.
// It must fit together with the instructions on any screen, so it is bounded by
// both the width and the height of the window, with a floor that stays scannable.
const WIDTH_SHARE = 0.25;
const HEIGHT_SHARE = 0.4;
const MIN_SIZE = 120;

export function joinQrSize(width, height) {
  const size = Math.floor(Math.min(width * WIDTH_SHARE, height * HEIGHT_SHARE));
  return Math.max(size, MIN_SIZE);
}
