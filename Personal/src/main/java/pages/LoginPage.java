package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class LoginPage {
	
	public WebDriver driver;
	
	public LoginPage(WebDriver driver) {
		this.driver = driver;	
	}
	
	private By txtUsername = By.id("username");
	public By txtUsername() {
		return txtUsername;
	}	

	private By txtPassword = By.id("password");
	public By txtPassword() {
		return txtPassword;
	}

	private By btnLogin = By.id("loginButton");
	public By btnLogin() {
		return btnLogin;
	}
	
}
