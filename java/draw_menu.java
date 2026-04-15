// not functional yet. trying to implement it in the main script wil likely be near impossible and cause peroformance loss anyway
public class draw_menu {
    public static void main(String[] args) {
        //tput civis
        //tput cpu 00
        String main_theme = "\033[32m";
        System.out.print(main_theme);
        figlet(figlet_args, figlet_text);
        int line_count = 0;
        for (int i = 0; i < options.length; i++) {
            //tput el
            if (i == current) {
                System.out.print("➤ " + selected_theme + options.get(i) + unselected_theme + "\n");
            } else {
                System.out.print("  " + selected_theme + options.get(i) + unselected_theme + "\n");
            }
            line_count++;
        }
        for (int i = line_count; i < last_lines; i++) {
            //tput el
            System.out.print("\n");
        }
        last_lines = line_count
    }
}