import java.math.BigDecimal;
import processing.sound.*;
import java.util.Arrays;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.util.logging.*;
import static com.jogamp.newt.event.KeyEvent.*;
import java.text.SimpleDateFormat;
import java.util.Date;

// Create loggers
final Logger LOGGER_MAIN = Logger.getLogger("RocketResourceRaceMain"); // Most logs belong here INCLUDING EXCEPTION LOGS. Also I have put saving logs here rather than game
final Logger LOGGER_GAME = Logger.getLogger("RocketResourceRaceGame"); // For game algorithm related logs (not exceptions here, just things like party moving or ai making decision)
final Level FILELOGLEVEL = Level.FINEST;


String activeState;
HashMap<String, State> states;
int lastClickTime = 0;
final int DOUBLECLICKWAIT = 500;
final String LETTERSNUMBERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890/\\_ ";
HashMap<String, SoundFile> sfx;
int prevT;
HashMap<Integer, PFont> fonts;
PShader toon;
String loadingName;

JSONManager jsManager;
JSONObject gameData;

// Event-driven methods
void mouseClicked() {
  mouseEvent("mouseClicked", mouseButton);
  doubleClick();
}
void mouseDragged() {
  mouseEvent("mouseDragged", mouseButton);
}
void mouseMoved() {
  mouseEvent("mouseMoved", mouseButton);
}
void mousePressed() {
  mouseEvent("mousePressed", mouseButton);
}
void mouseReleased() {
  mouseEvent("mouseReleased", mouseButton);
}
void mouseWheel(MouseEvent event) {
  mouseEvent("mouseWheel", mouseButton, event);
}
void keyPressed() {
  keyboardEvent("keyPressed", key);
}
void keyReleased() {
  keyboardEvent("keyReleased", key);
}
void keyTyped() {
  keyboardEvent("keyTyped", key);
}

float between(float lower, float v, float upper) {
  return max(min(upper, v), lower);
}

color brighten(color old, int off) {
  return color(between(0, red(old)+off, 255), between(0, green(old)+off, 255), between(0, blue(old)+off, 255));
}

String roundDp(String val, int dps) {
  return (new BigDecimal(""+val).divide(new BigDecimal("1"), dps, BigDecimal.ROUND_HALF_EVEN).stripTrailingZeros()).toPlainString();
}

String roundDpTrailing(String val, int dps){
  return (new BigDecimal(""+val).divide(new BigDecimal("1"), dps, BigDecimal.ROUND_HALF_EVEN)).toPlainString();
} 

/*
Gets the index of the JSONObject with 'id' set to id in the JSONArray j
*/
int JSONIndex(JSONArray j, String id) {
  for (int i=0; i<j.size(); i++) {
    if (j.getJSONObject(i).getString("id").equals(id)) {
      return i;
    }
  }
  LOGGER_MAIN.warning(String.format("Invalid JSON index '%s'", id));
  return -1;
}

/*
Gets the JSONObject with 'id' set to id in the JSONArray j
*/
JSONObject findJSONObject(JSONArray j, String id) {
  try {
    for (int i=0; i<j.size(); i++) {
      if (j.getJSONObject(i).getString("id").equals(id)) {
        return j.getJSONObject(i);
      }
    }
  }
  catch(Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, String.format("Error finding object in JSON array, with id:'%s'", id), e);
    throw e;
  }
  return null;
}

boolean JSONContainsStr(JSONArray j, String id) {
  try {
    if (id == null || j == null)
      return false;
    for (int i=0; i<j.size(); i++) {
      if (j.getString(i).equals(id)) {
        return true;
      }
    }
    return false;
  }
  catch(Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, String.format("Error finding string in JSON array, '%s'", id), e);
    throw e;
  }
}
/*
Handles double clicks
*/
void doubleClick() {
  if (millis() - lastClickTime < DOUBLECLICKWAIT) {
    mouseEvent("mouseDoubleClicked", mouseButton);
    lastClickTime = 0;
  } else {
    lastClickTime = millis();
  }
}

float sigmoid(float x) {
  return 1-2/(exp(x)+1);
}

void mouseEvent(String eventType, int button) {
  getActiveState()._mouseEvent(eventType, button);
}
void mouseEvent(String eventType, int button, MouseEvent event) {
  getActiveState()._mouseEvent(eventType, button, event);
}
void keyboardEvent(String eventType, char _key) {
  if (key==ESC) {
    key = 0;
  }
  getActiveState()._keyboardEvent(eventType, _key);
}

void setVolume() {
  try {
    for (SoundFile fect : sfx.values()) {
      fect.amp(jsManager.loadFloatSetting("volume"));
    }
  }
  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Something wrong with setting volume", e);
    throw e;
  }
}

void setFrameRateCap() {
  LOGGER_MAIN.finer("Setting framerate cap");
  if (jsManager.loadBooleanSetting("framerate cap")) {
    frameRate(60);
  } else {
    frameRate(1000);
  }
}

int NUMOFGROUNDTYPES = 5;
int NUMOFBUILDINGTYPES = 9;
int TILESIZE = 1;
int MAPWIDTH = 100;
int MAPHEIGHT = 100;
float MAPHEIGHTNOISESCALE = 0.08;
float MAPTERRAINNOISESCALE = 0.08;
float HILLSTEEPNESS = 0.1;

HashMap<String, PImage> tileImages;
HashMap<String, PImage[]> buildingImages;
PImage[] partyBaseImages;
PImage[] partyImages;
PImage[] taskImages;
HashMap<String, PImage> lowImages;
HashMap<String, PImage> tile3DImages;
HashMap<String, PImage> equipmentImages;
PImage bombardImage;

void quitGame() {
  LOGGER_MAIN.info("Exitting game...");
  exit();
}

void loadSounds() {
  try {
    if (jsManager.loadBooleanSetting("sound on")) {
      sfx = new HashMap<String, SoundFile>();
      sfx.put("click3", new SoundFile(this, "wav/click3.wav"));
    }
  }
  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Something wrong with loading sounds", e);
    throw e;
  }
}

void loadImages() {
  try {
    LOGGER_MAIN.fine("Loading images");
    tileImages = new HashMap<String, PImage>();
    lowImages = new HashMap<String, PImage>();
    tile3DImages = new HashMap<String, PImage>();
    buildingImages = new HashMap<String, PImage[]>();
    equipmentImages = new HashMap<String, PImage>();
    
    partyBaseImages = new PImage[]{
      loadImage("img/party/battle.png"),
      loadImage("img/party/flag.png")
    };
    
    bombardImage = loadImage("img/ui/bombard.png");
    LOGGER_MAIN.finer("Loading task images");
    taskImages = new PImage[gameData.getJSONArray("tasks").size()];
    for (int i=0; i<gameData.getJSONArray("terrain").size(); i++) {
      JSONObject tileType = gameData.getJSONArray("terrain").getJSONObject(i);
      tileImages.put(tileType.getString("id"), loadImage("img/terrain/"+tileType.getString("img")));
      if (!tileType.isNull("low img")) {
        lowImages.put(tileType.getString("id"), loadImage("img/terrain/"+tileType.getString("low img")));
      }
      if (!tileType.isNull("img3d")) {
        tile3DImages.put(tileType.getString("id"), loadImage("img/terrain/"+tileType.getString("img3d")));
      }
    }
    LOGGER_MAIN.finer("Loading building images");
    for (int i=0; i<gameData.getJSONArray("buildings").size(); i++) {
      JSONObject buildingType = gameData.getJSONArray("buildings").getJSONObject(i);
      PImage[] p = new PImage[buildingType.getJSONArray("img").size()];
      for (int i2=0; i2< buildingType.getJSONArray("img").size(); i2++)
        p[i2] = loadImage("img/building/"+buildingType.getJSONArray("img").getString(i2));
      buildingImages.put(buildingType.getString("id"), p);
    }
    LOGGER_MAIN.finer("Loading task images");
    for (int i=0; i<gameData.getJSONArray("tasks").size(); i++) {
      JSONObject task = gameData.getJSONArray("tasks").getJSONObject(i);
      if (!task.isNull("img")) {
        taskImages[i] = loadImage("img/task/"+task.getString("img"));
      }
    }
    LOGGER_MAIN.finer("Loading equipment images");
    
    // Load equipment icons
    for (int c=0; c < jsManager.getNumEquipmentClasses(); c++){
      for (int t=0; t < jsManager.getNumEquipmentTypesFromClass(c); t++){
        String fn = jsManager.getEquipmentImageFileName(c, t);
        if (!fn.equals("")){
          equipmentImages.put(jsManager.getEquipmentTypeID(c, t), loadImage(fn));
          LOGGER_MAIN.finest("Loading equipment image id:"+jsManager.getEquipmentTypeID(c, t));
        } else {
          equipmentImages.put(jsManager.getEquipmentTypeID(c, t), createImage(1, 1, ALPHA));
          LOGGER_MAIN.finest("Loading empty image for equipment id:"+jsManager.getEquipmentTypeID(c, t));
        }
      }
    }
    
    LOGGER_MAIN.finer("Finished loading images");
  }

  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Something wrong with loading images", e);
    throw e;
  }
}

PFont getFont(float size) {
  try {
    PFont f=fonts.get(round(size));
    if (f == null) {
      fonts.put(round(size), createFont("GillSans", size));
      return fonts.get(round(size));
    } else {
      return f;
    }
  }
  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Something wrong with loading font", e);
    throw e;
  }
}


float sum(float[] l) {
  float c=0;
  for (int i=0; i<l.length; i++)
    c += l[i];
  return c;
}


float halfScreenWidth;
float halfScreenHeight;
void setup() {

  fullScreen(P3D);
  try {
    // Set up loggers
    FileHandler mainHandler = new FileHandler(sketchPath("main_log.log"));
    mainHandler.setFormatter(new LoggerFormatter());
    mainHandler.setLevel(FILELOGLEVEL);
    LOGGER_MAIN.addHandler(mainHandler);
    LOGGER_MAIN.setLevel(FILELOGLEVEL);

    FileHandler gameHandler = new FileHandler(sketchPath("game_log.log"));
    gameHandler.setFormatter(new LoggerFormatter());
    gameHandler.setLevel(FILELOGLEVEL);
    LOGGER_GAME.addHandler(gameHandler);
    LOGGER_GAME.setLevel(FILELOGLEVEL);
    LOGGER_GAME.addHandler(mainHandler);
    LOGGER_GAME.setLevel(FILELOGLEVEL);

    //Logger.getLogger("global").setLevel(Level.WARNING);
    //Logger.getLogger("").setLevel(Level.WARNING);
    //LOGGER_MAIN.setUseParentHandlers(false);

    LOGGER_MAIN.fine("Starting setup");

    fonts = new HashMap<Integer, PFont>();
    jsManager = new JSONManager();
    gameData = jsManager.gameData;
    loadSounds();
    setFrameRateCap();
    textFont(createFont("GillSans", 32));


    loadImages();
    LOGGER_MAIN.fine("Loading states");

    states = new HashMap<String, State>();
    addState("menu", new Menu());
    addState("map", new Game());
    activeState = "menu";
    //noSmooth();
    smooth();
    noStroke();
    //hint(DISABLE_OPTIMIZED_STROKE);
    halfScreenWidth = width/2;
    halfScreenHeight= height/2;
    //toon = loadShader("ToonFrag.glsl", "ToonVert.glsl");
    //toon.set("fraction", 1.0);

    LOGGER_MAIN.fine("Setup finished");
  }

  catch(IOException e) {
    LOGGER_MAIN.log(Level.SEVERE, "IO exception occured duing setup", e);
  }

  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Error occured during setup", e);
    throw e;
  }
}
boolean smoothed = false;

void draw() {
  try {
    background(255);
    prevT = millis();
    String newState = getActiveState().update();
    if (!newState.equals("")) {
      for (Panel panel : states.get(newState).panels) {
        for (Element elem : panel.elements) {
          elem.mouseEvent("mouseMoved", LEFT);
        }
      }
      states.get(activeState).leaveState();
      states.get(newState).enterState();
      activeState = newState;
    }
    if (jsManager.loadBooleanSetting("show fps")) {
      textFont(getFont(10));
      textAlign(LEFT, TOP);
      fill(255, 0, 0);
      text(frameRate, 0, 0);
    }
    if (jsManager.loadBooleanSetting("show fps")) {
      textFont(getFont(10));
      textAlign(LEFT, TOP);
      fill(255, 0, 0);
      text(frameRate, 0, 0);
    }
  }
  catch (Exception e) {
    LOGGER_MAIN.log(Level.SEVERE, "Uncaught exception occured during draw", e);
    throw e;
  }
}

State getActiveState() {
  State state = states.get(activeState);
  if (state == null) {
    LOGGER_MAIN.severe("State not found "+activeState);
  }
  return state;
}

void addState(String name, State state) {
  states.put(name, state);
}
