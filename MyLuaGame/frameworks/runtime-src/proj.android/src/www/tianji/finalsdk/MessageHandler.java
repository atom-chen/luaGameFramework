package www.tianji.finalsdk;

import android.app.Activity;
import android.os.Handler;
import android.os.Message;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;
import org.cocos2dx.lua.AppActivity;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;

/**
 * Created by ccy on 2017/8/4.
 */
public class MessageHandler extends Handler {
    private AppActivity activity;
    private static MessageHandler messageHandler = null;
    private HashMap<String, Integer> callbackHashMap = new HashMap<String, Integer>();
    private HashMap<String, String> sdkReturnInfo = new HashMap<String, String>();
    public MessageHandler(AppActivity activity){
        this.activity = activity;
        messageHandler = this;
    }

    /**
     * 这里不能直接调用Lua代码， 可能会出现ANR问题导致闪退
     * @param msg
     */
    @Override
    public void handleMessage(Message msg) {
        super.handleMessage(msg);
        String [] data = (String[])msg.obj;
        String funcName = data[0];
        String bundle = data[1];

        try {
            Method method = this.activity.getClass().getMethod(funcName, String.class);
            method.invoke(this.activity, bundle);
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }

    // public void receiveFromLua(String funcName, String bundle, int callbackId){
    //     this.callbackHashMap.put(funcName, callbackId);
    //     Class<? extends AppActivity> aClass = this.activity.getClass();
    //     try {
    //         Method method = aClass.getMethod(funcName, String.class);
    //         method.invoke(this,bundle);
    //     } catch (NoSuchMethodException e) {
    //         e.printStackTrace();
    //     } catch (IllegalAccessException e) {
    //         e.printStackTrace();
    //     } catch (InvocationTargetException e) {
    //         e.printStackTrace();
    //     }

    // }


    public void callbackToLua(String funcName, String bundle){
        Integer callback = callbackHashMap.get(funcName);
        // 防止腾讯那样的自动登录
        if(callback == null){
            sdkReturnInfo.put(funcName, bundle);
            return ;
        }
        // 根据需要，确定是否删除，比如像退出回调这种的函数，就不需要删除
//        if(SDKConfig.LOGOUT_FUNCNAME == funcName && SDKConfig.CLEAR_LOGOUT_CALLBACK ||
//                SDKConfig.LOGIN_FUNCNAME == funcName && SDKConfig.CLEAR_LOGIN_CALLBACK){
//            callbackHashMap.remove(funcName);
//        }
        callbackHashMap.remove(funcName);
        Cocos2dxLuaJavaBridge.callLuaFunctionWithString(callback, bundle);
    }

    /**
     * 将消息发送到主线程处理
     * @param funcName
     * @param bundle
     * @param callbackId
     */
    public void receiveMsg(String funcName, String bundle, int callbackId){
        callbackHashMap.put(funcName, callbackId);
        if(sdkReturnInfo.get(funcName) != null){
            callbackToLua(funcName, sdkReturnInfo.get(funcName));
            sdkReturnInfo.remove(funcName);
            return ;
        }
        Message message = new Message();
        String [] data = {funcName, bundle};
        message.obj = data;
        this.sendMessage(message);
    }


    /**
     *
     * 从lua到Java的桥
     * @param funcName 函数名
     * @param bundle 数据体 json格式
     * @param callbackId lua回调函数
     */
    public static void msgFromLua(String funcName, String bundle, int callbackId){
        messageHandler.receiveMsg(funcName, bundle, callbackId);
    }

}
