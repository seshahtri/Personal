package common;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;

import config.Constants;

public class Base {
	
	public WebDriver driver;
	static FileInputStream fis;
	static Properties prop = new Properties();

	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public WebDriver initDriver() throws IOException
	{
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		String webBrowser = prop.getProperty("browser");		
		if(webBrowser.contains("chrome")) {			
			System.setProperty("webdriver.chrome.driver", Constants.driver);
			HashMap<String, Object> chromePrefs = new HashMap<String, Object>();
			chromePrefs.put("profile.default_content_settings.popups", 0);
			chromePrefs.put("download.default_directory", Constants.downloadPath);

			ChromeOptions options = new ChromeOptions();
			options.setExperimentalOption("prefs", chromePrefs);
			
			if(webBrowser.contains("headless")) {
				options.addArguments("--headless");
			}
			driver = new ChromeDriver(options);
		}	
		
		driver.manage().timeouts().implicitlyWait(10, TimeUnit.SECONDS);
		driver.manage().window().maximize();
		return driver;
	}


	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> envCreds() throws IOException{
		ArrayList<String> data = new ArrayList<String>();
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		data.add("https://" + prop.getProperty("environment") + ".dev.wkelms.com/Passport/index.do");
		data.add(prop.getProperty("envUser"));
		data.add(prop.getProperty("envPasscode"));
		data.add(prop.getProperty("client"));
		return data;
	}

	
	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> clientDbCreds() throws IOException{
		ArrayList<String> data = new ArrayList<String>();
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		data.add("jdbc:sqlserver://" + prop.getProperty("clientDbServerName") + ";databaseName=");
		data.add(prop.getProperty("clientDbUser"));
		data.add(prop.getProperty("clientDbPasscode"));
		return data;		
	}
	
	
	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> autoDbCreds() throws IOException{
		ArrayList<String> data = new ArrayList<String>();
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		data.add("jdbc:sqlserver://" + prop.getProperty("autoDbServerName") + ";databaseName=");
		data.add(prop.getProperty("autoDbUser"));
		data.add(prop.getProperty("autoDbPasscode"));
		return data;		
	}

	
	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> passportDbCreds() throws IOException{
		ArrayList<String> data = new ArrayList<String>();
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		data.add("jdbc:sqlserver://" + prop.getProperty("passportDbServerName") + ";databaseName=");
		data.add(prop.getProperty("passportDbUser"));
		data.add(prop.getProperty("passportDbPasscode"));
		return data;		
	}
	
	
	/**
	 * 
	 * @param key
	 * @param value
	 * @throws IOException
	 */
	public static void setProperty(String key, String value) throws IOException {
		FileInputStream in = new FileInputStream(Constants.runtime);
		Properties props = new Properties();
		props.load(in);
		in.close();
	
		FileOutputStream out = new FileOutputStream(Constants.runtime);
		props.setProperty(key, value);
		props.store(out, null);
		out.close();
	}	
	
	
	/**
	 * 
	 * @param key
	 * @return
	 * @throws IOException
	 */
	public static String getStringConfigData(String key) throws IOException {
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		return prop.getProperty(key);
	}
	
	
	/**
	 * 
	 * @param key
	 * @return
	 * @throws IOException
	 */
	public static String getStringFilterData(String key) throws IOException {
		fis = new FileInputStream(Constants.filter);
		prop.load(fis);
		return prop.getProperty(key);
	}

	
	/**
	 * 
	 * @param key
	 * @return
	 * @throws IOException
	 */
	public static int getNumericConfigData(String key) throws IOException {
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		return Integer.parseInt((prop.getProperty(key)));
	}
	
	
	/**
	 * 
	 * @param key
	 * @return
	 * @throws IOException
	 */
	public static Boolean getBooleanConfigData(String key) throws IOException {
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		return Boolean.parseBoolean(prop.getProperty(key));
	}
	
	
	/**
	 * 
	 * @param key
	 * @return
	 * @throws IOException
	 */
	public static String getStringRunTimeData(String key) throws IOException {
		fis = new FileInputStream(Constants.runtime);
		prop.load(fis);
		return prop.getProperty(key);
	}
	
}
