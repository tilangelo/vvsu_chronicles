using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using GX = System.Drawing.Font;

// Top-down route plan for checking geometry before any tile work. 1 cell = 1 m = 1 tile.
// Ander: FABLAB plan pixels / 5 (scale from the OSM outline), origin at plan pixel (110, 150).
public static class Plan
{
    public class Map
    {
        public int W, H; public char[,] C;
        public Map(int w, int h) { W = w; H = h; C = new char[w, h]; Rect(0, 0, w, h, ' '); }
        public void Rect(int x, int y, int w, int h, char ch)
        {
            for (int j = y; j < y + h; j++) for (int i = x; i < x + w; i++) if (i >= 0 && j >= 0 && i < W && j < H) C[i, j] = ch;
        }
        public char At(int x, int y) { return (x < 0 || y < 0 || x >= W || y >= H) ? ' ' : C[x, y]; }
    }

    static Color Hex(string s) { return ColorTranslator.FromHtml("#" + s); }

    static readonly Dictionary<char, Color> Fill = new Dictionary<char, Color>
    {
        { '.', Hex("e4e7ea") }, { 'V', Hex("3a4150") }, { 'S', Hex("e0b050") }, { 'B', Hex("2b4a8c") }, { 'P', Hex("bfc9d8") },
        { 'Q', Hex("9c4a32") }, { 'N', Hex("243346") }, { 'O', Hex("9ea3a6") }, { 'M', Hex("7fd0e0") }, { 'L', Hex("3f78e0") },
        { 'T', Hex("d94040") }, { 'K', Hex("7a5cc0") }, { 'W', Hex("4aa35a") }, { 'H', Hex("b8e0be") }, { 'A', Hex("7a6a55") },
        { 'D', Hex("ffffff") }, { 'G', Hex("c9a074") }, { 'F', Hex("e8c8a8") }, { 'U', Hex("f4f0e6") },
        { 'J', Hex("6f7f96") }, { 'g', Hex("f0a0a0") }, { 'I', Hex("6b7078") }, { 'E', Hex("d9cdb8") }, { 'X', Hex("f6e27a") }, { 'Y', Hex("35c8e8") }, { 'Z', Hex("f08a3c") }
    };

    // Geometry follows the author's markup of the first draft, then scaled down 18% at the author's request.
    public static Map Ander()
    {
        Map m = new Map(56, 38);
        m.Rect(3, 5, 51, 11, '.');      // main promenade, 11 m wide north of the opening
        m.Rect(11, 2, 21, 3, '.');      // north bay in front of the theatre doors
        m.Rect(3, 2, 8, 4, 'K');        // security post at the turnstiles
        m.Rect(18, 16, 14, 9, '.');     // floor in front of the blue steps
        m.Rect(50, 16, 4, 12, '.');     // strip east of the opening
        m.Rect(49, 0, 5, 5, '.');       // additional corridor
        m.Rect(51, 0, 2, 1, 'D');
        m.Rect(54, 22, 2, 3, '.');      // corridor on the route
        m.Rect(55, 22, 1, 3, 'D');
        m.Rect(32, 16, 18, 9, 'V');     // opening to the lower level
        m.Rect(32, 21, 18, 4, 'J');     // tables and chairs on the lower level
        m.Rect(32, 25, 18, 3, 'F');     // cafes on the lower level
        m.Rect(32, 18, 3, 2, 'S');      // stairs down
        m.Rect(40, 16, 2, 3, 'S');      // second stairs down
        m.Rect(32, 28, 18, 9, 'U');     // Tochka Kipeniya, closed
        m.Rect(18, 16, 3, 8, 'X');      // photo zone
        m.Rect(18, 25, 14, 2, 'B');     // blue steps
        m.Rect(18, 27, 14, 10, 'P');    // raised platform
        m.Rect(18, 34, 9, 3, 'Q');      // coffee shop
        m.Rect(25, 26, 1, 1, 'M');      // mirror column
        foreach (int x in new int[] { 32, 37, 47 }) m.Rect(x, 15, 1, 1, 'O');
        foreach (int x in new int[] { 11, 18, 25, 31, 38, 44, 51 }) m.Rect(x, 6, 1, 1, 'N');
        m.Rect(53, 7, 1, 8, 'L');       // LED wall
        m.Rect(32, 5, 13, 1, 'G');      // brown glazing
        m.Rect(35, 5, 5, 1, 'A');       // aquarium
        m.Rect(45, 2, 4, 7, '.');       // stub to the underground passage, drawn by the author
        m.Rect(46, 5, 1, 4, 'T');       // its turnstiles, right behind the door in the west partition
        m.Rect(46, 7, 1, 1, 'g');       // passable gate
        m.Rect(45, 2, 4, 3, 'S');       // stairs down to the passage
        m.Rect(7, 6, 1, 10, 'T');       // ander turnstiles, wall to wall
        m.Rect(7, 10, 1, 1, 'g');       // passable gate
        m.Rect(3, 7, 1, 4, 'D');        // street entrance
        m.Rect(17, 2, 15, 1, 'Y');      // glass doors to the theatre
        m.Rect(31, 3, 1, 2, 'Z');       // canteen entrance
        return m;
    }

    // Main entrance from the author's sketch, scaled down 30% at the author's request: the hall is about 25 x 14 m.
    public static Map Entrance()
    {
        Map m = new Map(27, 16);
        m.Rect(2, 0, 25, 14, '.');
        m.Rect(2, 0, 19, 3, 'H');       // hangers behind the glass
        m.Rect(2, 3, 19, 1, 'W');       // counter and glass with windows
        m.Rect(22, 0, 5, 4, 'S');       // stairs up to the corridor
        foreach (int x in new int[] { 5, 10, 14, 18 }) m.Rect(x, 5, 1, 1, 'O');
        m.Rect(20, 6, 7, 1, 'I');       // metal fence from the turnstiles
        m.Rect(20, 7, 1, 7, 'T');       // turnstiles
        m.Rect(20, 9, 1, 1, 'g');       // passable gate
        m.Rect(18, 12, 2, 2, 'K');      // security post
        m.Rect(2, 12, 16, 1, 'E');      // windowsill
        m.Rect(2, 13, 15, 1, 'G');      // windows
        m.Rect(22, 13, 3, 1, 'D');      // inner door
        m.Rect(21, 14, 5, 2, '.');      // buffer vestibule, size assumed
        m.Rect(22, 15, 3, 1, 'D');      // street doors
        m.Rect(0, 4, 2, 2, '.');        // additional corridor
        m.Rect(0, 4, 1, 2, 'D');
        return m;
    }

    // Computer classroom 1421, after the classroom photos on the university site. The door row is the near edge.
    public static Map Classroom()
    {
        Map m = new Map(12, 10);
        m.Rect(0, 0, 12, 9, '.');
        foreach (int y in new int[] { 1, 4 })
        {
            m.Rect(2, y, 4, 2, 'J');    // chairs on the window side, desks on the door side
            m.Rect(7, y, 4, 2, 'J');
        }
        m.Rect(2, 7, 3, 1, 'J');        // teacher desk, right to the left of the door
        m.Rect(3, 8, 1, 1, 'J');        // teacher chair
        m.Rect(9, 8, 2, 1, 'J');        // cabinet
        m.Rect(5, 9, 2, 1, 'D');        // door to the corridor
        return m;
    }

    public static Map Corridor()
    {
        Map m = new Map(44, 3);
        m.Rect(0, 0, 44, 3, '.');
        m.Rect(0, 0, 3, 3, 'S');
        m.Rect(41, 0, 3, 3, 'S');
        for (int k = 0; k < 5; k++) m.Rect((int)Math.Round(5 + k * 8.8), 0, 1, 1, 'D');   // classroom doors on the far wall
        return m;
    }

    static void Draw(Graphics g, Map m, int ox, int oy, int s, bool gridLabels)
    {
        Pen grid = new Pen(Hex("cfd3d8")), wall = new Pen(Hex("14161c"), 3), rail = new Pen(Hex("29b6d8"), 4);
        for (int y = 0; y < m.H; y++)
            for (int x = 0; x < m.W; x++)
            {
                char c = m.C[x, y];
                if (c == ' ') continue;
                using (SolidBrush b = new SolidBrush(Fill[c])) g.FillRectangle(b, ox + x * s, oy + y * s, s, s);
                g.DrawRectangle(grid, ox + x * s, oy + y * s, s, s);
            }
        Func<int, int, bool> open = delegate (int x, int y) { return m.At(x, y) != ' '; };
        for (int y = 0; y < m.H; y++)
            for (int x = 0; x < m.W; x++)
            {
                if (!open(x, y)) continue;
                int px = ox + x * s, py = oy + y * s;
                if (!open(x, y - 1)) g.DrawLine(wall, px, py, px + s, py);
                if (!open(x, y + 1)) g.DrawLine(wall, px, py + s, px + s, py + s);
                if (!open(x - 1, y)) g.DrawLine(wall, px, py, px, py + s);
                if (!open(x + 1, y)) g.DrawLine(wall, px + s, py, px + s, py + s);
                if (m.W > 20 && (m.C[x, y] == 'V' || m.C[x, y] == 'F' || m.C[x, y] == 'J'))
                {
                    Func<char, bool> edge = delegate (char n) { return n != 'V' && n != 'F' && n != 'J' && n != 'S' && n != 'U' && n != ' '; };
                    if (edge(m.At(x, y - 1))) g.DrawLine(rail, px, py, px + s, py);
                    if (edge(m.At(x + 1, y))) g.DrawLine(rail, px + s, py, px + s, py + s);
                    if (edge(m.At(x - 1, y))) g.DrawLine(rail, px, py, px, py + s);
                }
            }
    }

    static void Arrow(Graphics g, Color c, float w, params PointF[] p)
    {
        using (Pen pen = new Pen(c, w))
        {
            pen.CustomEndCap = new AdjustableArrowCap(4, 5);
            pen.LineJoin = LineJoin.Round;
            g.DrawLines(pen, p);
        }
    }

    static void Cam(Graphics g, GX f, int ox, int oy, int s, float x, float y, float dx, float dy, string label)
    {
        Color c = Hex("d6209a");
        PointF a = new PointF(ox + x * s, oy + y * s), b = new PointF(ox + (x + dx) * s, oy + (y + dy) * s);
        Arrow(g, c, 2.5f, a, b);
        using (SolidBrush t = new SolidBrush(c)) g.FillEllipse(t, a.X - 4, a.Y - 4, 8, 8);
        SizeF z = g.MeasureString(label, f);
        g.FillRectangle(Brushes.White, a.X + 5, a.Y - z.Height - 2, z.Width, z.Height);
        using (SolidBrush t = new SolidBrush(c)) g.DrawString(label, f, t, a.X + 5, a.Y - z.Height - 2);
    }

    static void Tag(Graphics g, GX f, int x, int y, string s, Color fg, Color bg)
    {
        SizeF z = g.MeasureString(s, f);
        using (SolidBrush b = new SolidBrush(bg)) g.FillRectangle(b, x, y, z.Width, z.Height);
        using (SolidBrush b = new SolidBrush(fg)) g.DrawString(s, f, b, x, y);
    }

    static void Scale(Graphics g, GX f, int x, int y, int s, int metres)
    {
        g.FillRectangle(Brushes.Black, x, y, s * metres, 4);
        g.DrawString(metres + " м = " + metres + " тайлов", f, Brushes.Black, x, y + 6);
    }

    public static void Main(string[] args)
    {
        int W = 1560, H = 1180, s = 18;
        using (Bitmap bmp = new Bitmap(W, H))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
            g.Clear(Color.White);
            GX h1 = new GX("Segoe UI", 21, FontStyle.Bold), h2 = new GX("Segoe UI", 15, FontStyle.Bold);
            GX t = new GX("Segoe UI", 12), small = new GX("Segoe UI", 10.5f), bold = new GX("Segoe UI", 11, FontStyle.Bold);
            g.DrawString("ВВГУ: утверждённый план маршрута (вид сверху)", h1, Brushes.Black, 24, 12);
            g.DrawString("1 клетка = 1 м = 1 тайл. Андер: план этажа и контур OSM, затем уменьшено на 18%. Вход: набросок автора, уменьшено на 30%. Эти же данные лежат в картах игры.", t, Brushes.DimGray, 26, 54);

            // 3. Ander
            int ax = 24, ay = 118;
            g.DrawString("Андер, верхний уровень (3 этаж): версия с твоими правками", h2, Brushes.Black, ax, 90);
            Map an = Ander();
            Draw(g, an, ax, ay, s, true);
            using (Pen w = new Pen(Hex("14161c"), 3))
            {
                g.DrawRectangle(w, ax + 32 * s, ay + 28 * s, 18 * s, 9 * s);
                g.DrawRectangle(w, ax + 3 * s, ay + 2 * s, 8 * s, 4 * s);
                g.DrawLine(w, ax + 45 * s, ay + 5 * s, ax + 45 * s, ay + 9 * s);
                g.DrawLine(w, ax + 49 * s, ay + 2 * s, ax + 49 * s, ay + 9 * s);
                g.DrawLine(w, ax + 45 * s, ay + 9 * s, ax + 49 * s, ay + 9 * s);
                using (Pen door = new Pen(Hex("ffffff"), 4)) g.DrawLine(door, ax + 45 * s, ay + 7 * s, ax + 45 * s, ay + 9 * s);
            }
            Color dark = Hex("14161c"), wh = Color.White;
            Tag(g, bold, ax + 38 * s, ay + 20 * s, "проём на нижний уровень", wh, Fill['V']);
            Tag(g, bold, ax + 34 * s, ay + 22 * s, "столики и стулья внизу", wh, Fill['J']);
            Tag(g, bold, ax + 34 * s, ay + 25 * s, "кафе на нижнем уровне", dark, Fill['F']);
            Tag(g, bold, ax + 34 * s, ay + 32 * s, "«Точка кипения»: закрыта, не используется", dark, Fill['U']);
            Tag(g, small, ax + 33 * s, ay + 17 * s - 3, "вниз ↓", dark, wh);
            Tag(g, small, ax + 43 * s + 4, ay + 16 * s, "← вниз", dark, wh);
            Tag(g, bold, ax + 15 * s, ay + 8 * s, "главная галерея, ширина около 11 м", dark, Fill['.']);
            Tag(g, small, ax + 20 * s, ay + 25 * s + 3, "синие ступени вверх", wh, Fill['B']);
            Tag(g, small, ax + 22 * s, ay + 30 * s, "помост", dark, Fill['P']);
            Tag(g, small, ax + 20 * s, ay + 35 * s, "кофейня", wh, Fill['Q']);
            Tag(g, small, ax + 18 * s + 2, ay + 19 * s, "фотозона", dark, Fill['X']);
            Tag(g, small, ax + 17 * s, ay + 3 * s + 1, "↑ стеклянные двери в театр:", dark, Fill['.']);
            Tag(g, small, ax + 17 * s, ay + 4 * s + 1, "за ними прямо вход в театр, справа дверь в буфет", dark, Fill['.']);
            Tag(g, small, ax + 33 * s, ay + 2 * s, "← столовая", dark, wh);
            Tag(g, small, ax + 34 * s, ay + 6 * s + 3, "↑ аквариум", dark, wh);
            Tag(g, small, ax + 40 * s + 4, ay + 6 * s + 3, "↑ остекление", dark, wh);
            Tag(g, small, ax + 33 * s, ay + 2 * s - 4, "турникеты и спуск в подземный переход →", dark, wh);
            Tag(g, small, ax + 48 * s + 6, ay + 16 * s - 2, "LED-экран ↗", dark, wh);
            Tag(g, small, ax + 0, ay + 6 * s + 4, "тамбур,", dark, wh);
            Tag(g, small, ax + 0, ay + 7 * s + 7, "улица ↓", dark, wh);
            Tag(g, small, ax + 8 * s + 3, ay + 7 * s, "турникеты на всю ширину", dark, wh);
            Tag(g, bold, ax + 3 * s + 4, ay + 2 * s, "пост охраны", dark, wh);
            Tag(g, small, ax + 39 * s, ay + 0 + 2, "дополнительный коридор ↑", dark, wh);
            Tag(g, small, ax + 50 * s + 3, ay + 25 * s, "коридор ↗", dark, Fill['.']);
            PointF[] rt = new PointF[] {
                new PointF(ax + 55.5f * s, ay + 23.5f * s), new PointF(ax + 52f * s, ay + 23.5f * s),
                new PointF(ax + 52f * s, ay + 10.5f * s), new PointF(ax + 28f * s, ay + 10.5f * s) };
            Arrow(g, Hex("e03030"), 4, rt);
            Scale(g, small, ax + 2 * s, ay + 34 * s, s, 10);

            // right column
            int rx = 1080;
            g.DrawString("Главный вход и гардероб, 1 этаж", h2, Brushes.Black, rx, 90);
            g.DrawString("По твоему наброску, уменьшено на 30%: около 25 × 14 м", small, Brushes.DimGray, rx, 116);
            Map en = Entrance();
            int ex = rx - 10, ey = 142, es = 16;
            Draw(g, en, ex, ey, es, false);
            Tag(g, small, ex + 8 * es, ey + 1 * es, "вешалки", dark, Fill['H']);
            Tag(g, small, ex + 3 * es, ey + 4 * es + 1, "↑ стойка, стекло", dark, Fill['.']);
            Tag(g, small, ex + 22 * es, ey + 1 * es, "лестница", dark, Fill['S']);
            Tag(g, small, ex + 6 * es, ey + 10 * es + 4, "подоконник и окна ↓", dark, Fill['.']);
            Tag(g, small, ex + 13 * es, ey + 8 * es, "турникеты →", dark, Fill['.']);
            Tag(g, small, ex + 12 * es, ey + 15 * es, "двери с улицы →", dark, wh);
            Tag(g, small, ex + 16 * es, ey + 14 * es, "буфер →", dark, wh);
            Tag(g, small, ex + 9 * es, ey + 14 * es, "пост охраны ↗", dark, wh);
            Tag(g, small, ex - 1 * es, ey + 6 * es + 4, "доп. коридор", dark, Fill['.']);
            Arrow(g, Hex("e03030"), 3, new PointF(ex + 23.5f * es, ey + 15.5f * es), new PointF(ex + 23.5f * es, ey + 9.5f * es), new PointF(ex + 19 * es, ey + 9.5f * es),
                new PointF(ex + 19 * es, ey + 5 * es), new PointF(ex + 12 * es, ey + 5 * es), new PointF(ex + 12 * es, ey + 4.2f * es));
            Arrow(g, Hex("e03030"), 3, new PointF(ex + 12 * es, ey + 5.4f * es), new PointF(ex + 24 * es, ey + 5.4f * es), new PointF(ex + 24 * es, ey + 4.2f * es));

            int lx = rx, ly = 452;
            g.DrawString("Условные обозначения", h2, Brushes.Black, lx, ly);
            string[] names = {
                ".пол", "Vпроём", "Fкафе внизу", "Sлестница", "Bсиние ступени", "Pпомост", "Qкофейня", "Uзакрытая аудитория",
                "Xфотозона", "Yдвери в театр", "Zвход в столовую", "Nсиняя колонна", "Oсерая колонна", "Mзеркальная колонна",
                "LLED-экран", "Gостекление", "Aаквариум", "Tтурникеты", "Kпост охраны", "Dдверь", "Jстолики и стулья внизу", "Hвешалки", "Wстойка гардероба, стекло", "Iметаллический забор", "Eподоконник" };
            for (int i = 0; i < names.Length; i++)
            {
                int cx = lx + (i % 2) * 235, cy = ly + 32 + (i / 2) * 25;
                using (SolidBrush b = new SolidBrush(Fill[names[i][0]])) g.FillRectangle(b, cx, cy + 3, 18, 18);
                g.DrawRectangle(Pens.Gray, cx, cy + 3, 18, 18);
                g.DrawString(names[i].Substring(1), small, Brushes.Black, cx + 24, cy + 1);
            }
            using (Pen p = new Pen(Hex("e03030"), 4)) g.DrawLine(p, lx, ly + 362, lx + 22, ly + 362);
            g.DrawString("маршрут игрока", small, Brushes.Black, lx + 28, ly + 352);
            using (Pen p = new Pen(Hex("29b6d8"), 4)) g.DrawLine(p, lx + 235, ly + 362, lx + 257, ly + 362);
            g.DrawString("ограждение проёма", small, Brushes.Black, lx + 263, ly + 352);

            int kx = rx + 40, ky = 866, ks = 16;
            g.DrawString("Аудитория 1421, 4 этаж", h2, Brushes.Black, rx, 832);
            Draw(g, Classroom(), kx, ky, ks, false);
            Tag(g, small, kx + 13 * ks, ky + 0 * ks, "окна напротив двери", dark, wh);
            Tag(g, small, kx + 13 * ks, ky + 2 * ks, "мониторы к окну", dark, wh);
            Tag(g, small, kx + 13 * ks, ky + 7 * ks, "стол слева от входа", dark, wh);
            Tag(g, small, kx + 13 * ks, ky + 9 * ks, "дверь в коридор", dark, wh);

            // corridor
            int cy0 = 900, cs = 22;
            g.DrawString("4 этаж: коридор с компьютерными классами. Ширина взята с 3 этажа, аудиторий вдвое меньше", h2, Brushes.Black, ax, cy0 - 36);
            Map co = Corridor();
            int cx0 = ax + 40;
            Draw(g, co, cx0, cy0 + 40, cs, false);
            using (Pen door = new Pen(Hex("3f78e0"), 6))
                for (int k = 0; k < 5; k++)
                {
                    float dx = cx0 + (float)Math.Round(5 + k * 8.8) * cs;
                    g.DrawLine(door, dx, cy0 + 40, dx + 1.0f * cs, cy0 + 40);
                    g.DrawLine(door, dx, cy0 + 40 + 3 * cs, dx + 1.0f * cs, cy0 + 40 + 3 * cs);
                }
            Tag(g, small, cx0 + 5 * cs, cy0 + 18, "двери аудиторий, шаг 8,8 м, ширина коридора 3 м", dark, wh);
            Tag(g, small, cx0 + 0, cy0 + 40 + 3 * cs + 6, "← лестница к андеру", dark, wh);
            Tag(g, small, cx0 + 35 * cs, cy0 + 40 + 3 * cs + 6, "лестница с 1 этажа →", dark, wh);
            Tag(g, bold, cx0 + 9 * cs, cy0 + 40 + 3 * cs + 6, "аудитории 1413–1429, номера условные; цель: компьютерный класс 1421", Hex("3f78e0"), wh);
            Arrow(g, Hex("e03030"), 4, new PointF(cx0 + 41 * cs, cy0 + 40 + 1.5f * cs), new PointF(cx0 + 3 * cs, cy0 + 40 + 1.5f * cs));

            g.DrawString("Этажи разные, поэтому это пять отдельных карт: вход, коридор, класс 1421, андер и его нижний уровень.", t, Brushes.Black, ax, cy0 + 160);
            g.DrawString("Передние стены комнат в игре срезаются, чтобы не закрывать героя.", t, Brushes.DimGray, ax, cy0 + 184);

            bmp.Save(args[0], ImageFormat.Png);
        }
        Console.WriteLine("ok");
    }
}
