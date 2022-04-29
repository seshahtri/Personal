package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class HomePage {
	
	public WebDriver driver;
	
	public HomePage(WebDriver driver) {
		this.driver = driver;		
	}	
	
	private By linkAppHome = By.linkText("Application Home");
	public By linkAppHome() {
		return linkAppHome;
	}
}
