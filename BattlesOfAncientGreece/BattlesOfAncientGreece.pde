import java.util.*;

boolean DEBUG = false;

///////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL
///////////////////////////////////////////////////////////////////////////////////////////
// map
PGraphics background_map;
PShape greece;
int[] map_size = new int[] {1024, 768};
int[] map_pos = new int[] {-275, -250};
float scale_factor = 1.6;

// battle crosses
PGraphics crosses;
int[] crosses_size = new int[] {map_size[0], map_size[1]};
int[] crosses_pos = new int[] {0, 0};

// title
PGraphics title;
PImage border;
int[] title_size = new int[] {770, 70};
int[] title_pos = new int[] {(map_size[0] - title_size[0])/2, 0};

// faction sidebar
Faction curr_faction;
PGraphics sidebar_base, sidebar;
int[] sidebar_size = new int[] {200, 650};
int[] sidebar_pos = new int[] {15, 70};

// details
Battle curr_battle;
PImage details_background;
int[] details_size = new int[] {800, 625};
int[] details_pos = new int[] {(map_size[0] - details_size[0]) / 2, (map_size[1] - details_size[1]) / 2};

// fonts, icons and battles
Map<String, PFont> fonts;
Map<String, Icon> icons;
Map<String, Battle> battles;
Map<String, Faction> factions;

///////////////////////////////////////////////////////////////////////////////////////////
// ICON
///////////////////////////////////////////////////////////////////////////////////////////
abstract class Icon {
  int xSize;
  int ySize;
  
  public Icon(int xSize, int ySize) {
    this.xSize = xSize;
    this.ySize = ySize;
  }
  
  public void display(PGraphics pg, int x_pos, int y_pos) {};
  
  public void display(PGraphics pg, int x_pos, int y_pos, int x_size, int y_size) {};
}

class SVG extends Icon {
  PShape img;
  
  public SVG(PShape img, int xSize, int ySize) {
    super(xSize, ySize);
    this.img = img;
  }
  
  public void display(PGraphics pg, int x_pos, int y_pos) {
    pg.shape(img, x_pos, y_pos, xSize, ySize);
  }
  
  public void display(PGraphics pg, int x_pos, int y_pos, int x_size, int y_size) {
    pg.shape(img, x_pos, y_pos, x_size, y_size);
  }
}

class IMG extends Icon {
  PImage img;
  
  public IMG(PImage img, int xSize, int ySize) {
    super(xSize, ySize);
    this.img = img;
  }
  
  public void display(PGraphics pg, int x_pos, int y_pos) {
    pg.image(img, x_pos, y_pos, xSize, ySize);
  }
  
  public void display(PGraphics pg, int x_pos, int y_pos, int x_size, int y_size) {
    pg.image(img, x_pos, y_pos, x_size, y_size);
  }
}

void loadIcons(String path) {
  icons = new HashMap<String, Icon>();
  
  Table table = loadTable(path, "header");
  for (TableRow row : table.rows()) {
    String p = row.getString("path");
    String[] tokens = p.split("/");
    String last = tokens[tokens.length-1];
    String name = last.substring(0, last.lastIndexOf('.'));
    int xSize = row.getInt("xSize");
    int ySize = row.getInt("ySize");
    if (last.endsWith("svg"))
      icons.put(name, new SVG(loadShape(p), xSize, ySize));
    else
      icons.put(name, new IMG(loadImage(p), xSize, ySize));
  }
}
///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////
// FACTION
///////////////////////////////////////////////////////////////////////////////////////////
class Faction {
  String name;
  Icon icon;
  HashSet<String> battles_;
  int max_strength_land;
  int max_strength_naval;
  int xPos;
  int yPos;
  int xSize;
  int ySize;
  
  public Faction(String name, Icon icon) {
    this.name = name;
    this.icon = icon;
    this.battles_ = new HashSet<String>();
    this.max_strength_land = 0;
    this.max_strength_naval = 0;
    this.xSize = 50;
    this.ySize = 50;
  }
  
  public void addBattle(String battleName) {
    battles_.add(battleName);
  }
  
  public void updateMaxStrength(int max_strength, String battleType) {
    if (battleType.equals("land") && max_strength > this.max_strength_land)
      this.max_strength_land = max_strength;
    else if (battleType.equals("naval") && max_strength > this.max_strength_naval)
      this.max_strength_naval = max_strength;
  }
  
  public void setPosition(int xPos, int yPos) {
    this.xPos = xPos;
    this.yPos = yPos;
  }
  
  private boolean hover() {
    return mouseX >= xPos + sidebar_pos[0] && mouseX <= xPos + sidebar_pos[0] + xSize && 
           mouseY >= yPos + sidebar_pos[1] && mouseY <= yPos + sidebar_pos[1] + ySize;
  }
  
  public void displayStrength() {
    crosses.noStroke();
    
    for (Map.Entry<String, Battle> entry : battles.entrySet()) {
      Battle b = entry.getValue();
      
      if ((curr_faction.name.equals(b.belligerent1) && b.strength1 > 0) ||
          (curr_faction.name.equals(b.belligerent2) && b.strength2 > 0)) {
            
        // win
        if (curr_faction.name.equals(b.winner))  
          crosses.fill(128, 255, 0, 128);
        // defeat
        else
          crosses.fill(255, 51, 51, 128);
          
        float strength = 0;
        float max_strength = b.battleType.equals("land") ? max_strength_land : max_strength_naval;
        if (curr_faction.name.equals(b.belligerent1))
          strength = (float)b.strength1 / max_strength * 60;
        else
          strength = (float)b.strength2 / max_strength * 60;
        
        crosses.ellipseMode(CENTER);
        crosses.ellipse(b.xPos + icons.get("battle").xSize/2,
                        b.yPos + icons.get("battle").ySize/2,
                        strength, strength);
      }
    }
  }
  
  public void displayBattleIcons() {
    crosses.stroke(0);
    crosses.strokeWeight(1);
    
    for (Map.Entry<String, Battle> entry : battles.entrySet()) {
      String battle_name = entry.getKey();
      Battle b = entry.getValue();
      if (battles_.contains(battle_name))  
        crosses.fill(0);
      else
        crosses.fill(230, 237, 240);
      SVG i = (SVG)icons.get("battle");
      i.img.disableStyle();
      i.display(crosses, b.xPos, b.yPos);
    }
  }
  
  public void display(PGraphics pg, boolean transparent) {
    if (transparent)
      pg.tint(255, 128);
    else
      pg.noTint();
    icon.display(pg, xPos, yPos, xSize, ySize);
  }
  
  public void displayFactionName(PGraphics pg) {
    pg.stroke(128, 128, 128);
    pg.strokeWeight(1);
    pg.fill(255);
    pg.rect(xPos + xSize + 5, yPos + 5, textWidth(name) + 30, 20, 5, 5, 5, 5); 
    pg.fill(0);
    pg.textAlign(CENTER, CENTER);
    pg.textFont(fonts.get("cmuserif_roman16"), 16);
    pg.text(name, xPos + xSize + textWidth(name)/2 + 21, yPos + 15);
  }
  
  public void toggleIcon(PGraphics pg) {    
    if (hover()) {
      // display opaque faction icon
      display(pg, false);
      
      // display faction name beside the icon
      displayFactionName(pg);      
      
      // display "clear" icon over faction icon in the sidebar
      if (curr_faction == this) {
        sidebar.fill(255, 255, 255, 210);
        SVG i = (SVG)icons.get("close");
        i.img.disableStyle();
        i.display(sidebar, 
                  curr_faction.xPos + 13, curr_faction.yPos + 13, 
                  curr_faction.xSize - 26, curr_faction.ySize - 26);
      // display black / gray battle icons on the map
      } else if (curr_faction == null)
        displayBattleIcons();
    }
  }
  
  public void toggleSelection() {
    if (hover()) {
      if (curr_faction == this)
        curr_faction = null;
      else
        curr_faction = this;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////
// BATTLE
///////////////////////////////////////////////////////////////////////////////////////////
class Battle {
  int xPos;
  int yPos;
  String name;
  int year;
  String belligerent1;
  String belligerent2;
  String battleType;
  int strength1;
  int strength2;
  int casualties1;
  int casualties2;
  String leader1;
  String leader2;
  String result;
  String winner;
  String partOf;
  String wikiUrl;
  String youtubeUrl;
  Icon icon1;
  Icon icon2;
  
  PGraphics banner;
  int[] banner_size;
  
  PGraphics strength_bar;
  int[] strength_bar_size;
  int[] strength_bar_pos;
  
  PGraphics details;
  
  color color1 = color(49, 119, 232);
  color color2 = color(184, 50, 88);

  public Battle(int xPos, int yPos, String name, int year, 
                String belligerent1, String belligerent2, String battleType,
                int strength1, int strength2, int casualties1, int casualties2,
                String leader1, String leader2, String result, String winner, 
                String partOf, String wikiUrl, String youtubeUrl, 
                Icon icon1, Icon icon2) {
    this.xPos = xPos;
    this.yPos = yPos;
    this.name = name;
    this.year = year;
    this.belligerent1 = belligerent1;
    this.belligerent2 = belligerent2;
    this.battleType = battleType;
    this.strength1 = strength1;
    this.strength2 = strength2;
    this.casualties1 = casualties1;
    this.casualties2 = casualties2;
    this.leader1 = leader1;
    this.leader2 = leader2;
    this.result = result;
    this.winner = winner;
    this.partOf = partOf;
    this.wikiUrl = wikiUrl;
    this.youtubeUrl = youtubeUrl;
    this.icon1 = icon1;
    this.icon2 = icon2;

    createBanner();
    createStrengthBar();
    this.details = null;
  }

  public String toString() {
    return String.format("%s\n%d BC", name, year);
  }

  private boolean hover() {
    Icon icon = icons.get("battle");
    return mouseX >= xPos && mouseX <= xPos + icon.xSize && 
           mouseY >= yPos && mouseY <= yPos + icon.ySize;
  }
  
  private void createBanner() {
    banner_size = new int[] {(int)textWidth(toString()) + 25, 40};
    banner = createGraphics(banner_size[0], banner_size[1]);
    
    banner.beginDraw();
    
    // white background with black border
    banner.fill(255);
    banner.stroke(0);
    banner.strokeWeight(1);
    banner.rect(0, 0, banner_size[0]-2, banner_size[1]-2, 5, 5, 5, 5);
    
    // battle name and year (black text)
    banner.fill(0);
    banner.textAlign(CENTER);
    banner.textFont(fonts.get("cmuserif_roman16"), 16);
    banner.text(toString(), banner_size[0]/2, 15);
    
    banner.endDraw();
  }
  
  void createStrengthBar() {
    strength_bar_size = new int[] {details_size[0], 100};
    strength_bar_pos = new int[] {115, 6*map_size[1]/7};
    strength_bar = createGraphics(strength_bar_size[0], strength_bar_size[1]);
    
    strength_bar.beginDraw();
    
    Icon icon;
        
    icon = battleType.equals("land") ? icons.get("strength") : icons.get("ship");
    icon.display(strength_bar, 
                 (100 - icon.xSize)/2, 
                 (strength_bar_size[1] - icon.ySize)/2);
    
    float share1 = (float)strength1 / (strength1 + strength2);
    float share2 = (float)strength2 / (strength1 + strength2);
    int span = strength_bar_size[0] - 200;
    float w1 = share1 * span;
    float w2 = share2 * span;
    strength_bar.noStroke();
    strength_bar.fill(color1);
    strength_bar.rect(100, 40, w1, 20, 5, 0, 0, 5);
    strength_bar.fill(color2);
    strength_bar.rect(100 + w1, 40, w2, 20, 0, 5, 5, 0);
    strength_bar.stroke(255, 255, 0);
    strength_bar.strokeWeight(2);
    strength_bar.line(100 + w1, 40, 100 + w1, 60);
    strength_bar.noStroke();
  
    if (casualties1 > 0 && casualties2 > 0) {
      // hatched white lines as casualty rate
      strength_bar.stroke(255);
      strength_bar.strokeWeight(1);
      share1 = (float)casualties1 / (strength1 + strength2);
      share2 = (float)casualties2 / (strength1 + strength2);
      w1 = share1 * span;
      w2 = share2 * span;
      for (int i = 100; i < w1+100-5; i += 8)
        strength_bar.line(i, 60, i+5, 40);
      for (int i = strength_bar_size[0]-100; i >= strength_bar_size[0]-100-w2+5; i -= 8)
        strength_bar.line(i, 60, i-5, 40);
        
      icon = battleType.equals("land") ? icons.get("death") : icons.get("ship_sunk");
      icon.display(strength_bar, 
                   (strength_bar_size[0] - 100) + (100 - icon.xSize)/2,
                   (strength_bar_size[1] - icon.ySize)/2);
    }
    
    strength_bar.endDraw();
  }
  
  private void displayMarkers(Faction opponent) {
    Faction f1;
    Faction f2;
    int w = 12;
    int h = 12;
    int r = 1;
    
    sidebar.stroke(255);
    sidebar.strokeWeight(2);
    
    if (curr_faction.name.equals(belligerent1)) {
      f1 = curr_faction;
      f2 = opponent;
    } else {
      f1 = opponent;
      f2 = curr_faction;
    }
    
    sidebar.fill(color1);
    sidebar.rect(f1.xSize + w/2, f1.yPos + f1.ySize/2 + 7, w, h, r, r, r, r);
    sidebar.fill(color2);
    sidebar.rect(f2.xSize + w/2, f2.yPos + f2.ySize/2 + 7, w, h, r, r, r, r);
  }
  
  private void createDetails() {
    Icon icon;
    int offset = 0;
    details = createGraphics(details_size[0], details_size[1]);
    
    details.beginDraw();
      
    // battle background image
    details.image(details_background, 0, 0, details_size[0], details_size[1]);
    
    // battle name and year in the middle
    details.textAlign(CENTER);
    details.fill(255, 0, 0);
    details.textFont(fonts.get("marathon"), 48);
    details.text(toString(), details_size[0]/2, 50);
    
    // notification about which war(s) does the battle belong to
    if (!partOf.isEmpty()) {
      details.textFont(fonts.get("marathon"), 24);
      details.text("Part of the " + partOf, details_size[0]/2, 100);
    }
    
    // icons of both belligerents
    icon1.display(details, details_size[0]/6, 30);
    icon2.display(details, 3*details_size[0]/4, 30);
    
    // names of both belligerents
    details.fill(0);
    details.textFont(fonts.get("spqr"), 24);
    details.text(belligerent1, details_size[0]/6 + icon1.xSize/2, 150);
    details.text(belligerent2, 3*details_size[0]/4 + icon2.xSize/2, 150);
    
    // leader's icon and leader names
    details.fill(0);
    details.textFont(fonts.get("cmuserif_roman16"), 16);
    if (!leader1.isEmpty() && !leader2.isEmpty()) {
      details.text(leader1, details_size[0]/6 + icon1.xSize/2, 180);
      details.text(leader2, 3*details_size[0]/4 + icon2.xSize/2, 180);
    } else if (!leader1.isEmpty() && leader2.isEmpty()) {
      details.text(leader1, details_size[0]/6 + icon1.xSize/2, 180);
    } else if (leader1.isEmpty() && !leader2.isEmpty()) {
      details.text(leader2, 3*details_size[0]/4 + icon2.xSize/2, 180);
    }
    
    // strength of both belligerents as a number
    offset = 240;
    if (strength1 > 0 && strength2 > 0) {
      details.fill(0);
      icon = battleType.equals("land") ? icons.get("strength") : icons.get("ship");
      icon.display(details, details_size[0]/2 - icon.xSize/2, 215 - icon.ySize);
      details.textFont(fonts.get("cmuserif_roman20"), 20);
      details.text(String.valueOf(strength1), 3*details_size[0]/8, 215);
      details.text(String.valueOf(strength2), 5*details_size[0]/8, 215);
      
      // strength of both belligerents as a colored bar
      float share1 = (float)strength1 / (strength1 + strength2);
      float share2 = (float)strength2 / (strength1 + strength2);
      int span = details_size[0] - 100;
      float w1 = share1 * span;
      float w2 = share2 * span;
      details.noStroke();
      details.fill(color1);
      details.rect(50, 235, w1, 20, 5, 0, 0, 5);
      details.fill(color2);
      details.rect(50 + w1, 235, w2, 20, 0, 5, 5, 0);
      details.stroke(255, 255, 0);
      details.strokeWeight(2);
      details.line(50 + w1, 235, 50 + w1, 255);
      details.noStroke();
    
      offset = 325;
      if (casualties1 > 0 && casualties2 > 0) {
        // hatched white lines as casualty rate
        details.stroke(255);
        details.strokeWeight(1);
        share1 = (float)casualties1 / (strength1 + strength2);
        share2 = (float)casualties2 / (strength1 + strength2);
        w1 = share1 * span;
        w2 = share2 * span;
        for (int i = 50; i < w1+50-5; i += 8)
          details.line(i, 255, i+5, 235);
        for (int i = details_size[0]-50; i >= details_size[0]-50-w2+5; i -= 8)
          details.line(i, 255, i-5, 235);
        
        // casualties of both belligerents as a number
        details.fill(0);
        icon = battleType.equals("land") ? icons.get("death") : icons.get("ship_sunk");
        int tmp = battleType.equals("land") ? 300 : 310;
        icon.display(details, details_size[0]/2 - icon.xSize/2, tmp - icon.ySize);
        details.textFont(fonts.get("cmuserif_roman20"), 20);
        details.text(String.valueOf(casualties1), 3*details_size[0]/8, tmp);
        details.text(String.valueOf(casualties2), 5*details_size[0]/8, tmp);
        
        offset = 390;
      }
    }
    
    // victory icon and battle result text
    details.fill(0);
    icon = icons.get("victory");
    icon.display(details, details_size[0]/2 - icon.xSize/2, offset - 20 - icon.ySize);
    details.textFont(fonts.get("cmuserif_roman20"), 20);
    details.text(String.valueOf(result), details_size[0]/2, offset);
    
    // wiki link image
    if (!wikiUrl.isEmpty()) {
      icons.get("wiki").display(details, 23*details_size[0]/25, details_size[1]/50);
      icons.get("pointer").display(details, 
        23*details_size[0]/25 + icons.get("wiki").xSize, details_size[1]/50);
    }
      
    // youtube link image
    if (!youtubeUrl.isEmpty()) {
      icons.get("youtube").display(details, 23*details_size[0]/25, 3*details_size[1]/50);
      icons.get("pointer").display(details, 
        23*details_size[0]/25 + icons.get("youtube").xSize, 3*details_size[1]/50);
    }
      
    // close icon
    icons.get("close").display(details, details_size[0]/50, details_size[1]/50);
    
    details.endDraw();
  }
  
  public void toggleBanner() {
    if (hover()) {
      // display banner above the battle cross
      Icon icon = icons.get("battle");
      image(banner, xPos + icon.xSize/2 - banner_size[0]/2, yPos - icon.ySize - 26);
      
      if (curr_faction != null &&
          (curr_faction.name.equals(belligerent1) || curr_faction.name.equals(belligerent2))) {
            
        // display opaque faction icon of opponent in battle and its faction name
        String opponent_name = curr_faction.name.equals(belligerent1) ? belligerent2 : belligerent1;
        Faction opponent = factions.get(opponent_name);
        opponent.display(sidebar, false);
        opponent.displayFactionName(sidebar);
        
        // display the belligerent strength bar at the bottom of the map
        if (strength1 > 0 && strength2 > 0) {
          image(strength_bar, strength_bar_pos[0], strength_bar_pos[1]);
          displayMarkers(opponent);
        }
      }
    }
  }

  public void toggleDetails() {
    if (hover()) {
      createDetails();
      curr_battle = this;
    } else
      details = null;
  }
}

void loadBattles(String path) {
  battles = new HashMap<String, Battle>();
  factions = new TreeMap<String, Faction>();

  Table table = loadTable(path, "header");
  for (TableRow row : table.rows()) {
    int xPos = row.getInt("xPos");
    int yPos = row.getInt("yPos");
    String name = row.getString("name");
    int year = row.getInt("year");
    String belligerent1 = row.getString("belligerent1");
    String belligerent2 = row.getString("belligerent2");
    String battleType = row.getString("battleType");
    int strength1 = row.getInt("strength1");
    int strength2 = row.getInt("strength2");
    int casualties1 = row.getInt("casualties1");
    int casualties2 = row.getInt("casualties2");
    String leader1 = row.getString("leader1");
    String leader2 = row.getString("leader2");
    String result = row.getString("result");
    String winner = row.getInt("winner") == 1 ? belligerent1 : belligerent2;
    String partOf = row.getString("partOf");
    String wikiUrl = row.getString("wikiUrl");
    String youtubeUrl = row.getString("youtubeUrl");
    Icon icon1 = icons.get(row.getString("icon1"));
    Icon icon2 = icons.get(row.getString("icon2"));
    
    Battle battle = new Battle(xPos, yPos, name, year, belligerent1, belligerent2, battleType,
                               strength1, strength2, casualties1, casualties2, leader1, leader2, 
                               result, winner, partOf, wikiUrl, youtubeUrl, icon1, icon2);
    battles.put(name, battle);
    
    Faction faction1 = factions.get(belligerent1);
    if (faction1 == null)
      faction1 = new Faction(belligerent1, icon1);
    faction1.addBattle(name);
    faction1.updateMaxStrength(strength1, battleType);
    factions.put(belligerent1, faction1);
    
    Faction faction2 = factions.get(belligerent2);
    if (faction2 == null)
      faction2 = new Faction(belligerent2, icon2);
    faction2.addBattle(name);
    faction2.updateMaxStrength(strength2, battleType);
    factions.put(belligerent2, faction2); 

    if (DEBUG)
      println(xPos + ", " + yPos + ", " + name + ", " + year + ", " + belligerent1 + ", " + 
        belligerent2 + ", " + battleType + ", " + strength1 + ", " + strength2 + ", " + 
        casualties1 + ", " + casualties2 + ", " + leader1 + ", " + leader2 + ", " + 
        result + ", " + winner + ", " + partOf + ", " + wikiUrl + ", " + youtubeUrl + ", " + 
        row.getString("icon1") + ", " + row.getString("icon2"));
  }
}
///////////////////////////////////////////////////////////////////////////////////////////

void loadFonts(String path) {
  fonts = new HashMap<String, PFont>();

  for (String p : loadStrings(path)) {
    String[] tokens = p.split("/");
    String last = tokens[tokens.length-1];
    String name = last.substring(0, last.lastIndexOf('.'));
    fonts.put(name, loadFont(p));
  }
}

void createMap() {
  background_map = createGraphics(map_size[0], map_size[1]);
  
  background_map.beginDraw();
  
  // draw the svg representing the map of Greece, Aegean sea and Asia Minor
  background_map.shape(greece, 
    map_pos[0], map_pos[1], 
    map_size[0] * scale_factor, map_size[1] * scale_factor);

  // draw black battle icons on the map
  background_map.fill(0);
  for (Map.Entry<String, Battle> entry : battles.entrySet()) {
   Battle b = entry.getValue();
   SVG i = (SVG)icons.get("battle");
   i.img.disableStyle();
   i.display(background_map, b.xPos, b.yPos);
  }
    
  background_map.endDraw();
}

void createCrosses() {
  crosses = createGraphics(crosses_size[0], crosses_size[1]);
}

void createTitle() {
  title = createGraphics(title_size[0], title_size[1]);
  
  title.beginDraw();
  
  int offset = 18;
  title.image(border, 0, 0);
  title.fill(255);
  title.noStroke();
  title.rect(offset, offset, title_size[0] - 2*offset, title_size[1] - 2*offset);
  title.fill(0);
  title.textAlign(CENTER, CENTER);
  title.textFont(fonts.get("spqr"), 40);
  title.text("BATTLES OF ANCIENT GREECE", title_size[0]/2, title_size[1]/2);
  
  title.endDraw();
}

void createSidebar() {
  sidebar_base = createGraphics(sidebar_size[0], sidebar_size[1]);
  sidebar = createGraphics(sidebar_size[0], sidebar_size[1]);
  
  sidebar_base.beginDraw();
  
  int i = 0;
  for (Map.Entry<String, Faction> entry : factions.entrySet()) {
    Faction f = entry.getValue();
    f.setPosition(0, i++ * 60);
    f.display(sidebar_base, true);
  }
  
  sidebar_base.endDraw();
}

void dots() {
  fill(0);
  for (int i = 1; i < 11; i++) {
    for (int j = 1; j < 8; j++) {
      ellipse(i * 100, j * 100, 5, 5);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  size(1024, 768);
  
  // set the application title
  surface.setTitle("Battles of Ancient Greece");
  
  // load the map, the battle details background image and border texture
  greece = loadShape("data/greece.svg");
  details_background = loadImage("data/background.jpg");
  border = loadImage("data/border.png");
  
  // load the fonts, the icon images and battles' information
  loadFonts("data/fonts.txt");
  loadIcons("data/icons.csv");
  loadBattles("data/battles.csv");
  
  // create the svg map (with transparent faction icons and opaque battle icons) 
  createMap();
  
  // create gray battle crosses
  createCrosses();
  
  // create the map title
  createTitle();
  
  // create the factions' sidebar
  createSidebar();
  
  // init current battle and current faction
  curr_battle = null;
  curr_faction = null;
}

///////////////////////////////////////////////////////////////////////////////////////////
void draw() {  
  // display the map and the battle icons
  image(background_map, 0, 0);
  
  // draw the coordinate dots
  if (DEBUG)
    dots();

  if (curr_battle != null) {
    // display the detailed battle information window (on click)
    image(curr_battle.details, details_pos[0], details_pos[1]);
  } else {
    // display the bordered map title
    image(title, title_pos[0], title_pos[1]);
    
    // display the transparent faction icons on the side
    image(sidebar_base, sidebar_pos[0], sidebar_pos[1]);
    
    // display opaque faction icons on the side (on click, on hover)
    sidebar.beginDraw();
    crosses.beginDraw();
    
    sidebar.clear();
    crosses.clear();
    
    if (curr_faction != null) {
      curr_faction.display(sidebar, false);
      curr_faction.displayFactionName(sidebar);
      curr_faction.displayStrength();
      curr_faction.displayBattleIcons();
    }
    
    for (Map.Entry<String, Faction> entry : factions.entrySet())
        entry.getValue().toggleIcon(sidebar);
    
    crosses.endDraw();
    image(crosses, crosses_pos[0], crosses_pos[1]);
    
    // on hover display the banners above icons, 
    // strength of factions' forces in battles as ellipses and
    // battle strength bar at the bottom of the map
    for (Map.Entry<String, Battle> entry : battles.entrySet())
      entry.getValue().toggleBanner();
      
    sidebar.endDraw();
    image(sidebar, sidebar_pos[0], sidebar_pos[1]);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////
void mouseReleased() {
  Icon icon1, icon2;
  
  // open the wikipedia link describing battle in browser
  icon1 = icons.get("wiki");
  icon2 = icons.get("pointer");
  if (curr_battle != null && !curr_battle.wikiUrl.isEmpty() &&
      mouseX >= details_pos[0] + 23*details_size[0]/25 && 
      mouseX < details_pos[0] + 23*details_size[0]/25 + icon1.xSize + icon2.xSize && 
      mouseY >= details_pos[1] + details_size[1]/50 && 
      mouseY <= details_pos[1] + details_size[1]/50 + icon1.ySize) {
    link(curr_battle.wikiUrl);
    
  // open the youtube link describing battle in browser
  icon1 = icons.get("youtube");
  icon2 = icons.get("pointer");
  } else if (curr_battle != null && !curr_battle.youtubeUrl.isEmpty() &&
      mouseX >= details_pos[0] + 23*details_size[0]/25 && 
      mouseX < details_pos[0] + 23*details_size[0]/25 + icon1.xSize + icon2.xSize && 
      mouseY >= details_pos[1] + 3*details_size[1]/50 && 
      mouseY <= details_pos[1] + 3*details_size[1]/50 + icon1.ySize) {
    link(curr_battle.youtubeUrl);
    
  // close the battle details window
  icon1 = icons.get("close");
  } else if (curr_battle != null && 
      mouseX >= details_pos[0] + details_size[0]/50 && 
      mouseX < details_pos[0] + details_size[0]/50 + icon1.xSize && 
      mouseY >= details_pos[1] + details_size[1]/50 && 
      mouseY <= details_pos[1] + details_size[1]/50 + icon1.ySize) {
    curr_battle = null;
    
  } else if (curr_battle == null) {
    // open the battle details window
    for (Map.Entry<String, Battle> entry : battles.entrySet())
      entry.getValue().toggleDetails();
      
    // select / deselect current faction
    for (Map.Entry<String, Faction> entry : factions.entrySet())
        entry.getValue().toggleSelection();
  }
  
  if (DEBUG)
    println(mouseX + " " + mouseY);
}

void keyPressed() {
  if (key == ESC) {
    key = 0;
    // close the battle details window
    if (curr_battle != null)
      curr_battle = null;
    // deselect currently selected faction
    else if (curr_faction != null)
      curr_faction = null;
  }
}