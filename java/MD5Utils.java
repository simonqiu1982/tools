package test;
import org.apache.commons.codec.digest.DigestUtils;
 
public class MD5Utils {
 
    public static String md5Hex(String message) {
       return DigestUtils.md5Hex(message);
    }
 
    public static void main(String[] args) throws Exception {
    }
 
}