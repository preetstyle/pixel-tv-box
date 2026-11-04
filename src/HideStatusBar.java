import android.os.IBinder;
import android.os.Binder;
import java.lang.reflect.Method;

public class HideStatusBar {
    public static void main(String[] args) {
        try {
            Class<?> sm = Class.forName("android.os.ServiceManager");
            Method getService = sm.getMethod("getService", String.class);
            IBinder b = (IBinder) getService.invoke(null, "statusbar");
            Class<?> stub = Class.forName("com.android.internal.statusbar.IStatusBarService$Stub");
            Method asInterface = stub.getMethod("asInterface", IBinder.class);
            Object sb = asInterface.invoke(null, b);
            
            IBinder token = new Binder();
            Method d1 = sb.getClass().getMethod("disableForUser", int.class, IBinder.class, String.class, int.class);
            Method d2 = sb.getClass().getMethod("disable2ForUser", int.class, IBinder.class, String.class, int.class);
            
            // 0x009F0000:
            // DISABLE_EXPAND = 0x00010000
            // DISABLE_NOTIFICATION_ICONS = 0x00020000
            // DISABLE_NOTIFICATION_ALERTS = 0x00040000
            // DISABLE_NOTIFICATION_TICKER = 0x00080000
            // DISABLE_SYSTEM_INFO = 0x00100000
            // DISABLE_CLOCK = 0x00800000
            // DOES NOT touch DISABLE_HOME (0x00200000) or DISABLE_BACK (0x00400000)!
            int what1 = 0x009F0000;
            
            // what2:
            // DISABLE2_QUICK_SETTINGS = 1
            // DISABLE2_SYSTEM_ICONS = 2
            // DISABLE2_NOTIFICATION_SHADE = 4
            int what2 = 0x00000007;
            
            d1.invoke(sb, what1, token, "com.android.systemui", 0);
            d2.invoke(sb, what2, token, "com.android.systemui", 0);
            
            System.out.println("Status bar & clock disabled successfully (what1=" + Integer.toHexString(what1) + ")!");
            
            while (true) {
                Thread.sleep(60000);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
