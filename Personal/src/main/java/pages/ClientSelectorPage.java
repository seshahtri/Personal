package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class ClientSelectorPage {

	public WebDriver driver;
	
	public ClientSelectorPage(WebDriver driver) {
		this.driver = driver;	
	}
	
	private By linkClientSelector = By.linkText("Client Selector");
	public By linkClientSelector() {
		return linkClientSelector;
	}

	private By listClientSelector = By.cssSelector("#clientSelector > center:nth-child(1) > div > select");
	public By listClientSelector() {
		return listClientSelector;
	}
	
}
