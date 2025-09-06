package generalplus.com.GPCamLib;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.widget.Toast;

public class IncomingCall extends BroadcastReceiver {
	
	private Context m_Context;
	private String	TAG = "IncomingCall";

	public void onReceive(Context context, Intent intent) {
		
		m_Context = context;

		try {
			// TELEPHONY MANAGER class object to register one listner
			TelephonyManager tmgr = (TelephonyManager) context
					.getSystemService(Context.TELEPHONY_SERVICE);

			// Create Listner
			MyPhoneStateListener PhoneListener = new MyPhoneStateListener();

			// Register listener for LISTEN_CALL_STATE
			tmgr.listen(PhoneListener, PhoneStateListener.LISTEN_CALL_STATE);

		} catch (SecurityException se) {
			Log.e(TAG, "전화 상태 수신 등록 중 보안 예외 발생", se);
			// 필요 시 사용자에게 권한 요청 안내
		} catch (IllegalArgumentException iae) {
			Log.e(TAG, "전화 상태 수신 등록 중 잘못된 인자", iae);
		} catch (NullPointerException npe) {
			Log.e(TAG, "TelephonyManager가 초기화되지 않음", npe);
		} catch (Exception e) {
			Log.e(TAG, "전화 상태 수신 등록 중 알 수 없는 오류", e);
		}

	}

	private class MyPhoneStateListener extends PhoneStateListener {

		public void onCallStateChanged(int state, String incomingNumber) {

			Log.d(TAG, state + " incoming no:" + incomingNumber);
		}
	}
}