package check;

import com.google.gson.Gson;

// Prints through gson, so the jar runs only if the shade plugin bundled its dependency.
public class Main {
	public static void main(String[] args) {
		System.out.println(new Gson().toJson(new String[] {"shaded"}));
	}
}
