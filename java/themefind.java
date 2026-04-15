import java.util.HashMap;
public class themefind {
    public static void main(String[] argv) {
        HashMap<String, String> colors = new HashMap<>();
        colors.put("black", "\033[30m");
        colors.put("red", "\033[31m");
        colors.put("green", "\033[32m");
        colors.put("yellow", "\033[33m");
        colors.put("blue", "\033[34m");
        colors.put("magenta", "\033[35m");
        colors.put("cyan", "\033[36m");
        colors.put("white", "\033[37m");
        colors.put("gray", "\033[90m");
        colors.put("brightred", "\033[91m");
        colors.put("brightgreen", "\033[92m");
        colors.put("brightyellow", "\033[93m");
        colors.put("brightblue", "\033[94m");
        colors.put("brightmagenta", "\033[95m");
        colors.put("brightcyan", "\033[96m");
        colors.put("brightwhite", "\033[97m");
        String color = "\033[0m";
        if (argv.length > 0) {
            color = colors.getOrDefault(argv[0], "\033[0m");
        }
        System.out.print(color);
    }
}
