package util;


import java.util.Comparator;

public class Node {
    public int cost;
    public boolean fixed;
    public int prevX = -1;
    public int prevY = -1;
    public int x;
    public int y;

    public Node(int cost, boolean fixed, int prevX, int prevY) {
        this.fixed = fixed;
        this.cost = cost;
        this.prevX = prevX;
        this.prevY = prevY;
    }

    public Node(int cost, boolean fixed, int prevX, int prevY, int x, int y) {
        this.fixed = fixed;
        this.cost = cost;
        this.prevX = prevX;
        this.prevY = prevY;
        this.x = x;
        this.y = y;
    }
    public void setPrev(int prevX, int prevY) {
        this.prevX = prevX;
        this.prevY = prevY;
    }
}
