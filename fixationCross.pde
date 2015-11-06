public void fixationCross(){
  pushMatrix();
    translate(w/2, h/2);
    stroke(250);
    line(-fc, 0, fc, 0);
    line(0, -fc, 0, fc);
  popMatrix();
}
