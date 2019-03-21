package state.elements;

import json.JSONManager;
import processing.core.PGraphics;
import state.Element;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.logging.Level;

import static json.JSONManager.gameData;
import static processing.core.PApplet.ceil;
import static processing.core.PApplet.max;
import static processing.core.PConstants.*;
import static util.Font.getFont;
import static util.Logging.LOGGER_MAIN;
import static util.Util.papplet;

public class ResourceSummary extends Element {
    float[] stockPile, net;
    String[] resNames;
    int numRes, scroll;
    boolean expanded;
    int[] timings;
    byte[] warnings;

    final int GAP = 10;
    final int FLASHTIMES = 500;

    public ResourceSummary(int x, int y, int h, String[] resNames, float[] stockPile, float[] net) {
      this.x = x;
      this.y = y;
      this.h = h;
      this.resNames = resNames;
      this.numRes = resNames.length;
      this.stockPile = stockPile;
      this.net = net;
      this.expanded = false;
      this.timings = new int[resNames.length];
      this.warnings = new byte[resNames.length];
    }

    public void updateStockpile(float[] v) {
      try {
        stockPile = v;
        LOGGER_MAIN.finest("Stockpile update: " + Arrays.toString(v));
      }
      catch(Exception e) {
        LOGGER_MAIN.log(Level.WARNING, "Error updating stockpile", e);
        throw e;
      }
    }
    public void updateNet(float[] v) {
      try {
        LOGGER_MAIN.finest("Net update: " + Arrays.toString(v));
        net = v;
      }
      catch(Exception e) {
        LOGGER_MAIN.log(Level.WARNING, "Error updating net", e);
        throw e;
      }
    }

    public void updateWarnings(byte[] v) {
      try {
        LOGGER_MAIN.finest("Warnings update: " + Arrays.toString(v));
        warnings = v;
      }
      catch(Exception e) {
        LOGGER_MAIN.log(Level.WARNING, "Error updating warnings", e);
        throw e;
      }
    }

    public void toggleExpand() {
      expanded = !expanded;
      LOGGER_MAIN.finest("Expanded changed to: " + expanded);
    }
    public String prefix(String v) {
      try {
        float i = Float.parseFloat(v);
        if (i >= 1000000)
          return (new BigDecimal(v).divide(new BigDecimal("1000000"), 1, BigDecimal.ROUND_HALF_EVEN).stripTrailingZeros()).toPlainString()+"M";
        else if (i >= 1000)
          return (new BigDecimal(v).divide(new BigDecimal("1000"), 1, BigDecimal.ROUND_HALF_EVEN).stripTrailingZeros()).toPlainString()+"K";

        return (new BigDecimal(v).divide(new BigDecimal("1"), 1, BigDecimal.ROUND_HALF_EVEN).stripTrailingZeros()).toPlainString();
      }
      catch (Exception e) {
        LOGGER_MAIN.log(Level.SEVERE, "Error creating prefix", e);
        throw e;
      }
    }

    public String getResString(int i) {
      return resNames[i];
    }
    public String getStockString(int i) {
      String tempString = prefix(""+stockPile[i]);
      return tempString;
    }
    public String getNetString(int i) {
      String tempString = prefix(""+net[i]);
      if (net[i] >= 0) {
        return "+"+tempString;
      }
      return tempString;
    }
    public int columnWidth(int i) {
      int m=0;
        papplet.textFont(getFont(10*JSONManager.loadFloatSetting("text scale")));
      m = max(m, ceil(papplet.textWidth(getResString(i))));
        papplet.textFont(getFont(8*JSONManager.loadFloatSetting("text scale")));
      m = max(m, ceil(papplet.textWidth(getStockString(i))));
        papplet.textFont(getFont(8* JSONManager.loadFloatSetting("text scale")));
      m = max(m, ceil(papplet.textWidth(getNetString(i))));
      return m;
    }
    public int totalWidth() {
      int tot = 0;
      for (int i=numRes-1; i>=0; i--) {
        if (gameData.getJSONArray("resources").getJSONObject(i).getInt("resource manager") <= ((expanded) ? 0:1)) continue;
        tot += columnWidth(i)+GAP;
      }
      return tot;
    }

    public void flash(int i) {
      timings[i] = papplet.millis()+FLASHTIMES;
    }
    public int getFill(int i) {
      if (timings[i] < papplet.millis()) {
        return papplet.color(100);
      }
      return papplet.color(155*(timings[i]-papplet.millis())/FLASHTIMES+100, 100, 100);
    }

    public String getResourceAt(int x, int y) {
      return "";
    }

    public void draw(PGraphics panelCanvas) {
      int cw = 0;
      int w, yLevel, tw = totalWidth();
      panelCanvas.pushStyle();
      panelCanvas.textAlign(LEFT, TOP);
      panelCanvas.fill(120);
      panelCanvas.rect(papplet.width-tw-x-GAP/2, y, tw, h);
      panelCanvas.rectMode(CORNERS);
      for (int i=numRes-1; i>=0; i--) {
        if (gameData.getJSONArray("resources").getJSONObject(i).getInt("resource manager") <= ((expanded) ? 0:1)) continue;
        w = columnWidth(i);
        panelCanvas.fill(getFill(i));
        panelCanvas.textFont(getFont(10*JSONManager.loadFloatSetting("text scale")));
        panelCanvas.rect(papplet.width-cw+x-GAP/2, y, papplet.width-cw+x-GAP/2-(w+GAP), y+panelCanvas.textAscent()+panelCanvas.textDescent());
        cw += w+GAP;
        panelCanvas.line(papplet.width-cw+x-GAP/2, y, papplet.width-cw+x-GAP/2, y+h);
        panelCanvas.fill(0);

        yLevel=0;
        panelCanvas.textFont(getFont(10*JSONManager.loadFloatSetting("text scale")));
        panelCanvas.text(getResString(i), papplet.width-cw, y);
        yLevel += panelCanvas.textAscent()+panelCanvas.textDescent();

        panelCanvas.textFont(getFont(8*JSONManager.loadFloatSetting("text scale")));
        if (warnings[i] == 1) {
          panelCanvas.fill(255, 127, 0);
        } else if (warnings[i] == 2){
          panelCanvas.fill(255, 0, 0);
        }
        panelCanvas.text(getStockString(i), papplet.width-cw, y+yLevel);
        yLevel += panelCanvas.textAscent()+panelCanvas.textDescent();

        if (net[i] < 0)
          panelCanvas.fill(255, 0, 0);
        else
          panelCanvas.fill(0, 255, 0);
        panelCanvas.textFont(getFont(8*JSONManager.loadFloatSetting("text scale")));
        panelCanvas.text(getNetString(i), papplet.width-cw, y+yLevel);
        yLevel += panelCanvas.textAscent()+panelCanvas.textDescent();
      }
      panelCanvas.popStyle();
    }
  }
