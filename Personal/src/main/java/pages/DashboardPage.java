package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class DashboardPage {
	
	public WebDriver driver;
	
	public DashboardPage(WebDriver driver) {
		this.driver = driver;	
	}	

	private By dashVizzes = By.xpath("//*[@id='visualizations']/div/div/div");
	public By dashVizzes() {
		return dashVizzes;
	}	

}
