package com.hiboubougie.app;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * Notification « Concentration en cours » avec compte à rebours, visible sur l'écran de verrouillage
 * pendant le minuteur. Sur Android 16, elle est proposée comme « mise à jour en direct ».
 */
@CapacitorPlugin(name = "FocusTimer")
public class FocusTimerPlugin extends Plugin {
    private static final String CHANNEL = "focus_timer";
    private static final int ID = 4242;

    @SuppressLint("MissingPermission")
    @PluginMethod
    public void start(PluginCall call) {
        Context ctx = getContext();
        Double endD = call.getDouble("end");
        if (endD == null) { call.reject("end manquant"); return; }
        long end = endD.longValue();
        long left = end - System.currentTimeMillis();
        if (left <= 0) { call.resolve(); return; }

        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            call.resolve();
            return;
        }

        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= 26 && nm != null) {
            NotificationChannel ch = new NotificationChannel(CHANNEL, call.getString("channel", "Minuteur"), NotificationManager.IMPORTANCE_LOW);
            ch.setShowBadge(false);
            ch.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
            nm.createNotificationChannel(ch);
        }

        Intent open = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        PendingIntent pi = open == null ? null :
            PendingIntent.getActivity(ctx, 0, open, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationCompat.Builder b = new NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(ctx.getApplicationInfo().icon)
            .setContentTitle(call.getString("title", "Hibou & Bougie"))
            .setContentText(call.getString("body", ""))
            .setWhen(end)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setTimeoutAfter(left);
        if (pi != null) b.setContentIntent(pi);
        // Android 16 : demande l'affichage en « mise à jour en direct » (puce près de l'heure)
        b.getExtras().putBoolean("android.requestPromotedOngoing", true);

        NotificationManagerCompat.from(ctx).notify(ID, b.build());
        call.resolve();
    }

    @PluginMethod
    public void stop(PluginCall call) {
        NotificationManagerCompat.from(getContext()).cancel(ID);
        call.resolve();
    }
}
