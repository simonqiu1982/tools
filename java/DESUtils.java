package test;
import java.io.UnsupportedEncodingException;
import java.security.SecureRandom;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.DESKeySpec;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.lang3.StringUtils;
 
public class DESUtils {
 
	//DES加密
	public static String __encrypt(String data, String key) throws UnsupportedEncodingException, Exception {
	   
        if (StringUtils.isAnyBlank(key)) throw new RuntimeException("Please pass 2 parameters which are not null"); 
        byte[] bt = encrypt(data.getBytes("utf-8"), key.getBytes("utf-8"));
        String strs = Base64.encodeBase64String(bt);
        return strs;
	    
	}
	
	private static byte[] encrypt(byte[] data, byte[] key) throws Exception {
	    SecureRandom sr = new SecureRandom();
	    DESKeySpec dks = new DESKeySpec(key);
	    SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DES");
	    SecretKey securekey = keyFactory.generateSecret(dks);
	    Cipher cipher = Cipher.getInstance("DES");
	    cipher.init(Cipher.ENCRYPT_MODE, securekey, sr);
	    return cipher.doFinal(data);
	}

    public static void main(String[] args) throws Exception {
    	String resultString = __encrypt("441298989888888878","bb635dd47e5861f717472df95652077356a8f38dea6347851c191f66b7cf9dc8");
    
    	System.out.println(resultString);
    }
 
}