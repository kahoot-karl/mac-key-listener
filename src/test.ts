import { KeyListener } from ".";

new KeyListener((pressedKeys) => {
  console.log("Currently pressed keys:", pressedKeys);
});
