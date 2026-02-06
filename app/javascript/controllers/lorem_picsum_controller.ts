import { Controller } from "@hotwired/stimulus";

export default class LoremPicsumController extends Controller<HTMLImageElement> {
  // == Lifecycle ==

  connect() {
    const { width, height } = this.element.getBoundingClientRect();
    this.element.src = `https://picsum.photos/${scaleSize(width)}/${scaleSize(height)}`;
  }
}

// == Helpers ==

const scaleSize = (size: number): number => {
  return size * devicePixelRatio;
};
