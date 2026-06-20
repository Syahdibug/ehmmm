package APK.SYAHID.BUG;

import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.SYAHID/device";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (call.method.equals("getBatteryTemp")) {
                try {
                    IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
                    Intent batteryStatus = registerReceiver(null, ifilter);
                    if (batteryStatus != null) {
                        int tempRaw = batteryStatus.getIntExtra(
                            BatteryManager.EXTRA_TEMPERATURE, 0
                        );
                        double temp = tempRaw / 10.0;
                        result.success(temp);
                    } else {
                        result.success(null);
                    }
                } catch (Exception e) {
                    result.error("UNAVAILABLE", e.getMessage(), null);
                }
            } else {
                result.notImplemented();
            }
        });
    }
}