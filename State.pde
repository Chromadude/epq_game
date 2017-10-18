
class State{
  ArrayList<Panel> panels;
  String newState;
  
  State(){
    panels = new ArrayList<Panel>();
    addPanel("default", 0, 0, width, height, true, color(255), color(0));
    newState = "";
  }
  
  String update(){
    drawPanels();
    return newState;
  }
  void addPanel(String id, int x, int y, int w, int h, Boolean visible, color bgColour, color strokeColour){
    // Adds new panel to front
    panels.add(new Panel(id, x, y, w, h, visible, bgColour, strokeColour));
  }
  void addElement(String id, Element elem){
    getPanel("default").elements.put(id, elem);
  }
  void addElement(String id, Element elem, String panel){
    getPanel(panel).elements.put(id, elem);
  }
  
  void removeElement(String elementID, String panelID){
    getPanel(panelID).elements.remove(elementID);
  }
  void removePanel(String id){
    panels.remove(findPanel(id));
  }
  
  int findPanel(String id){
    for (int i=0; i<panels.size(); i++){
      if (panels.get(i).id.equals(id)){
        return i;
      }
    }
    return -1;
  }
  Panel getPanel(String id){
    return panels.get(findPanel(id));
  }
  
  void drawPanels(){
    // Draw the panels in reverse order (highest in the list are drawn last so appear on top)
    for (int i=panels.size()-1; i>=0; i--){
      if (panels.get(i).visible){
        panels.get(i).draw();
      }
    }
  }
  // Empty method for use by children
  void mouseEvent(String eventType, int button){}
  void mouseEvent(String eventType, int button, MouseEvent event){}
  void keyboardEvent(String eventType, int _key){}
  void elementEvent(String id, String eventType){}
  
  void elementEvent(ArrayList<Event> events){
    for (Event event : events){
      println(event.info());
    }
  }
  
  
  void _mouseEvent(String eventType, int button){
    ArrayList<Event> events = new ArrayList<Event>();
    mouseEvent(eventType, button);
    for (Panel panel : panels){
      if(panel.mouseOver()){
        for (String id : panel.elements.keySet()){
          for (String eventName : panel.elements.get(id)._mouseEvent(eventType, button)){
            events.add(new Event(id, eventName));
          }
        }
        break;
      }
    }
    elementEvent(events);
  }
  void _mouseEvent(String eventType, int button, MouseEvent event){
    ArrayList<Event> events = new ArrayList<Event>();
    mouseEvent(eventType, button, event);
    for (Panel panel : panels){
      if(panel.mouseOver()){
        for (String id : panel.elements.keySet()){
          for (String eventName : panel.elements.get(id)._mouseEvent(eventType, button, event)){
            events.add(new Event(id, eventName));
          }
        }
        break;
      }
    }
    elementEvent(events);
  }
  void _keyboardEvent(String eventType, char _key){
    keyboardEvent(eventType, _key);
    for (Panel panel : panels){
      for (Element elem : panel.elements.values()){
        // TODO decide whether all or just active panel
        if (elem.active){
          elem._keyboardEvent(eventType, _key);
        }
      }
    }
  }
}