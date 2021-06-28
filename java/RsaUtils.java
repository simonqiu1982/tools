package test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.util.Arrays;

public class RsaUtils {
	private static final char[] HEX_ARRAY = "0123456789ABCDEF".toCharArray();

	public static void main(String[] args) throws Exception {
		String modulus ="bf196ed884b4fcb6b47c68bd888a5c28c42276f119f416df82ef74b15d3525215779ebdbf981c9c197fef6c6e0746c1bd786e489fc65736d3b93bbb6842ea592ec7426f0ff060d919fde55ebcfed82ffeb5188fa1c9429a0a8c80e090b1059c2e97e1800ca5521d32b8de37c279aba82ca556c8daf86027776c3dcdac0dc33b1";
		String publicExponent = "10001";
		
	    String result = encrypt("Admin1234@",modulus, publicExponent);
	    System.out.println(result);
	}
	
	public static String encrypt(String password, String modulus, String publicExponent) throws Exception {
        int byteSize = byteSize(new BigInteger(modulus, 16));
        
        byte[] byteArray = _pad_for_encryption(password, byteSize);
    	
		BigInteger payLoad = new BigInteger(1, byteArray);
		
		BigInteger encrypted = encrypt_int(modulus, publicExponent, payLoad);
		
		byte[] block = toByteArrayUnsigned(encrypted);
		
		String result = bytesToHex(block);
		
		return result;
		
    }
	
	public static byte[] toByteArrayUnsigned(BigInteger bi) {
        byte[] extractedBytes = bi.toByteArray();
        int skipped = 0;
        boolean skip = true;
        for (byte b : extractedBytes) {
            boolean signByte = b == (byte) 0x00;
            if (skip && signByte) {
                skipped++;
                continue;
            } else if (skip) {
                skip = false;
            }
        }
        extractedBytes = Arrays.copyOfRange(extractedBytes, skipped,
                extractedBytes.length);
        return extractedBytes;
    }


	private static BigInteger encrypt_int(String modulus, String publicExponent, BigInteger payLoad) {
		BigInteger modulusVal = new BigInteger(modulus, 16);
		BigInteger publicExponentVal = new BigInteger(publicExponent, 16);
		
		if(payLoad.compareTo(BigInteger.ZERO) == -1) {
			throw new RuntimeException("Only non-negative numbers are supported");
		}
		
		if(payLoad.compareTo(modulusVal) == 1) {
			throw new RuntimeException("The payLoad is too long");
		}
		
		BigInteger encrypted = payLoad.modPow(publicExponentVal, modulusVal);
		return encrypted;
	}

	private static byte[] _pad_for_encryption(String password, int byteSize) throws IOException {
		password = new StringBuffer(password).reverse().toString();
        int encryptStringLength = password.length();
        int paddingLength = byteSize - encryptStringLength - 3;
        byte[] padding = new byte[paddingLength+3];
        for(int i=0;i<paddingLength+3;i++) {
        	padding[i]=(byte) 0x00;
        }
        ByteArrayOutputStream os = new ByteArrayOutputStream();
		os.write(padding);
		os.write(password.getBytes("utf-8"));
		byte[] byteArray = os.toByteArray();
		return byteArray;
	}
	
	 private static String bytesToHex(byte[] bytes) {
	    char[] hexChars = new char[bytes.length * 2];
	    for (int j = 0; j < bytes.length; j++) {
	        int v = bytes[j] & 0xFF;
	        hexChars[j * 2] = HEX_ARRAY[v >>> 4];
	        hexChars[j * 2 + 1] = HEX_ARRAY[v & 0x0F];
	    }
	    return new String(hexChars);
	}
	
	 private static int byteSize(BigInteger bi) {
		int l = (bi.bitLength() + 7) / 8;
        
		return l == 0 ? 1 : l;
	}
	
}
