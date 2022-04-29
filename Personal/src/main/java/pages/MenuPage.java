package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class MenuPage {

	public WebDriver driver;
	
	public MenuPage(WebDriver driver) {
		this.driver = driver;	
	}	

	private By btnMenu = By.cssSelector("#app > div > div.wk-react-app.main-navbar-container.wk-block-display-element > nav.navbar.navbar-default.menubar > div > ul.nav.navbar-nav.menubar-fixed-buttons > li:nth-child(2) > a");
	public By btnMenu() {
		return btnMenu;
	}
	
	private By menuDashboard = By.cssSelector("#app > div > div.wk-react-app.main-navbar-container.wk-block-display-element > nav.navbar.navbar-default.menubar > div > ul.nav.navbar-nav.menubar-fixed-buttons > li.dropdown.open > div > div > div.mega-menu > ul > li:nth-child(1) > ul > li");
	public By menuDashboard() {
		return menuDashboard;
	}
	
	
}
