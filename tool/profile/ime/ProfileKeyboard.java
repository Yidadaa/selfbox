package com.selfbox.profileime;

import android.inputmethodservice.InputMethodService;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;

public final class ProfileKeyboard extends InputMethodService {
    @Override
    public boolean onEvaluateInputViewShown() {
        return true;
    }

    @Override
    public boolean onEvaluateFullscreenMode() {
        return false;
    }

    @Override
    public View onCreateInputView() {
        LinearLayout keyboard = new LinearLayout(this);
        keyboard.setOrientation(LinearLayout.VERTICAL);
        keyboard.setBackgroundColor(0xffdce0e8);
        int rowHeight = Math.round(70 * getResources().getDisplayMetrics().density);
        for (String characters : new String[]{"qwertyuiop", "asdfghjkl", "zxcvbnm", " ⌫↓"}) {
            LinearLayout row = new LinearLayout(this);
            for (int index = 0; index < characters.length(); index++) {
                String character = characters.substring(index, index + 1);
                Button key = new Button(this);
                key.setText(character);
                key.setPadding(0, 0, 0, 0);
                key.setOnClickListener(new View.OnClickListener() {
                  @Override
                  public void onClick(View view) {
                    if (character.equals("↓")) {
                        requestHideSelf(0);
                    } else if (getCurrentInputConnection() != null) {
                        if (character.equals("⌫")) {
                            getCurrentInputConnection().deleteSurroundingText(1, 0);
                        } else {
                            getCurrentInputConnection().commitText(character, 1);
                        }
                    }
                  }
                });
                row.addView(key, new LinearLayout.LayoutParams(0, rowHeight, 1));
            }
            keyboard.addView(row);
        }
        return keyboard;
    }
}
