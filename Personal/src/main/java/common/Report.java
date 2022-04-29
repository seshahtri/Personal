package common;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;

import org.apache.commons.lang3.time.DurationFormatUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import config.Constants;

public class Report{
	
	Base base;
	
	public Report() throws IOException {
		this.base = new Base();
	}	
	
	private static int rowNum;
	private static int repRowNum;
	private static int sumRowNum;
	private static int repSumRowNum;
	private static int modSumRowNum;
	private static int repModSumRowNum;	
	private static int successCounter;
	private static int errorCounter;
	private static int warningCounter;
	private static int suiteSuccessCounter;
	private static int suiteErrorCounter;
	private static int suiteWarningCounter;	

	private static String testStartTime;
	private static String suiteStartDateTime;
	private static String duration;

	private static String dashboardName;
	private static String vizName;
	private static String sheetName;
	private static String summarySheetName = "TestSummary";
	private static String moduleSummarySheetName = "ModuleSummary";
	
	ArrayList<String> moduleReportCaption = new ArrayList<String>();
	public static int moduleErrCounter=0;;
	public static String tempFirstVizName;
	public static String tempSecondVizName;

	ArrayList<String> testDurationList = new ArrayList<String>();
	public static Logger log  = LogManager.getLogger(Modules.class.getName());
	
	
	/**
	 * 
	 * @return
	 */
	private XSSFWorkbook getXLWorkbook() {
        try {        	
    		File file = new File(Constants.repPath());
    		XSSFWorkbook workbook = null;    		
			if(file.exists()) {
				FileInputStream fis = new FileInputStream(file);
				ZipSecureFile.setMinInflateRatio(0);
	        	workbook = new XSSFWorkbook(fis);
		        fis.close();
		        return workbook;
			} else {				
	        	FileOutputStream fos = new FileOutputStream(Constants.repPath());
	    		ZipSecureFile.setMinInflateRatio(0);
	        	workbook = new XSSFWorkbook();
	        	fos.close();
	        	return workbook;
			}
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
		return null;
	}
	

	/**
	 * 
	 * @param workbook
	 * @param sheetName
	 * @return
	 */
	private XSSFSheet getXLSheet(XSSFWorkbook workbook, String sheetName) {
    	if (workbook.getNumberOfSheets() == 0) {
        	return workbook.createSheet(sheetName);
    	} 
    	else {
    		for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
    			if(workbook.getSheetName(i).equals(sheetName)) {
    				return workbook.getSheetAt(i);
    			}
    		}
    	}
    	return workbook.createSheet(sheetName);
	}
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleHeaderLabel(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)14);
    	font.setColor(IndexedColors.WHITE.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.GREY_50_PERCENT.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.CENTER);  
		style.getBorderLeft();
		return style;
	}
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleFooterLabel(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)13);
    	font.setColor(IndexedColors.WHITE.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.GREY_50_PERCENT.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.CENTER);  
		style.getBorderLeft();
		return style;
	}
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleHeader(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)13);
    	font.setColor(IndexedColors.WHITE.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.GREY_50_PERCENT.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.CENTER);  
		style.getBorderLeft();
		return style;
	}
		
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleTestDetails(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(false);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLACK.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleTestLightGreyFill(XSSFWorkbook workbook) {

		CellStyle style = workbook.createCellStyle();
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.index);
		return style;
	}
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleTestLogDetails(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(false);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLACK.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	

	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle stylePassLog(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLUE.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleFailLog(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.WHITE.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.DARK_RED.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleWarningLog(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLACK.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.LIGHT_YELLOW.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	
	
	
	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleNALog(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(true);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLACK.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
		style.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.index);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	
	

	/**
	 * 
	 * @param workbook
	 * @return
	 */
	private CellStyle styleStepLog(XSSFWorkbook workbook) {

    	Font font = workbook.createFont();
    	font.setBold(false);
    	font.setFontHeightInPoints((short)12);
    	font.setColor(IndexedColors.BLACK.index);

		CellStyle style = workbook.createCellStyle();
		style.setFont(font);
		style.setAlignment(HorizontalAlignment.LEFT);
		style.setVerticalAlignment(VerticalAlignment.BOTTOM);  
		return style;
	}	
	
	
	/**
	 * 
	 */
	private void createTestSummaryReportHeader() {		
        try {        	
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, summarySheetName);    				
    	    String[] columnHeadings = {"Step","Dashboard","VizName","Success","Error(s)","Warning(s)","Duration","Sheet Reference"};
			Row row = sheet.createRow(5);			

			for(int j=0;j<columnHeadings.length;j++) {
				Cell cell = row.createCell(j);
				cell.setCellValue(columnHeadings[j]);
				cell.setCellStyle(styleHeader(workbook));
			}
			sheet.createFreezePane(0, 6);
			
    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	
	
	
	/**
	 * 
	 */
	private void createModuleSummaryReportHeader() {		
        try {        	
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, moduleSummarySheetName);   	
    		
    		while (sheet.getNumMergedRegions() > 0) {
    		    for (int i = 0; i < sheet.getNumMergedRegions(); i++) {
    		        sheet.removeMergedRegion(i);
    		    }
    		}  		
    		
	        Row row = sheet.createRow(0);
	        row.createCell(0).setCellValue("Module Summary");
	        sheet.addMergedRegion(new CellRangeAddress(0,0,0,moduleReportCaption.size()-1));
    		Cell cell = sheet.getRow(0).getCell(0);
    		cell.setCellStyle(styleHeaderLabel(workbook));
    		
    	    row = sheet.createRow(1);		
			for(int j=0;j<moduleReportCaption.size();j++) {
				cell = row.createCell(j);
				cell.setCellValue(moduleReportCaption.get(j));
				cell.setCellStyle(styleHeader(workbook));
			}
			sheet.createFreezePane(0, 1);

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	

	
	/**
	 * 
	 */
	private void createDetailSummaryReportHeader() {		
        try {        	
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);   	        	
    	    String[] columnHeadings = {"Step","Result","Notes","Data"};
			Row row = sheet.createRow(0);
			
			for(int j=0;j<columnHeadings.length;j++) {
				Cell cell = row.createCell(j);
				cell.setCellValue(columnHeadings[j]);
				cell.setCellStyle(styleHeader(workbook));
			}
			sheet.createFreezePane(0, 1);

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}
	
	
	/**
	 * 
	 * @throws ParseException
	 */
	private void createTestSummaryReportHeaderDetails() throws ParseException {		
        try {       	
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, summarySheetName); 
    		
    		while (sheet.getNumMergedRegions() > 0) {
    		    for (int i = 0; i < sheet.getNumMergedRegions(); i++) {
    		        sheet.removeMergedRegion(i);
    		    }
    		}  		
    		
	        Row row = sheet.createRow(0);
	        row.createCell(0).setCellValue("Test Summary");
	        sheet.addMergedRegion(new CellRangeAddress(0,0,0,7));
    		Cell cell = sheet.getRow(0).getCell(0);
    		cell.setCellStyle(styleHeaderLabel(workbook));
    		
	        row = sheet.createRow(1);
	        row.createCell(0).setCellValue("Environment");
	        sheet.addMergedRegion(new CellRangeAddress(1,1,0,1));
    		cell = sheet.getRow(1).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(Base.getStringConfigData("environment"));
	        sheet.addMergedRegion(new CellRangeAddress(1,1,2,7));
    		cell = sheet.getRow(1).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));

    		
	        row = sheet.createRow(2);
	        row.createCell(0).setCellValue("Client");
	        sheet.addMergedRegion(new CellRangeAddress(2,2,0,1));
    		cell = sheet.getRow(2).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(Base.getStringConfigData("client"));
	        sheet.addMergedRegion(new CellRangeAddress(2,2,2,7));
    		cell = sheet.getRow(2).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));    

    		
	        row = sheet.createRow(3);
	        row.createCell(0).setCellValue("Datamart");
	        sheet.addMergedRegion(new CellRangeAddress(3,3,0,1));
    		cell = sheet.getRow(3).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(Base.getStringConfigData("clientDatabaseName"));
	        sheet.addMergedRegion(new CellRangeAddress(3,3,2,7));
    		cell = sheet.getRow(3).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));

    		
	        row = sheet.createRow(4);
	        row.createCell(0).setCellValue("Start Time");
	        sheet.addMergedRegion(new CellRangeAddress(4,4,0,1));
    		cell = sheet.getRow(4).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(suiteStartDateTime);
	        sheet.addMergedRegion(new CellRangeAddress(4,4,2,7));
    		cell = sheet.getRow(4).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));
	        
    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();       
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	
	
	
	/**
	 * 
	 */
	private void createDetailSummaryReportHeaderDetails() {		
        try {        	
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);    		
    		String [][] testDetails = new String [][] {  
	    	    {"","","Test Details", "*****"},    	        	
	    	    {"","","Dashboard", dashboardName},
	    	    {"","","Viz Name", vizName},    	        	
	    	    {"","","Start Time", getCurrentDateTime()}
    		};
    	    
    	    for (int i = 0; i < testDetails.length; i++) {
    			Row row = sheet.createRow(i+1);
    			for(int j = 0; j < testDetails[i].length; j++) {
    				Cell cell = row.createCell(j);
    				cell.setCellValue(testDetails[i][j]);
    				if (j < 2) 
    					cell.setCellStyle(styleTestLightGreyFill(workbook));
    				else 
    					cell.setCellStyle(styleTestDetails(workbook));
    			}
    	    }
			sheet.createFreezePane(0, 5);

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();	        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	
	

	/**
	 * 
	 * @param type
	 * @param msg
	 */
	private void createSuccessLog(String type, String msg) {
        try {        	
        	rowNum++;
        	repRowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);    		
			Row row = sheet.createRow(rowNum);
			
			Cell cell = row.createCell(0);
			cell.setCellValue(repRowNum);
			cell.setCellStyle(styleStepLog(workbook));
			
			cell = row.createCell(1);
			cell.setCellValue("PASS");
			cell.setCellStyle(stylePassLog(workbook));
			
			cell = row.createCell(2);
			cell.setCellValue(type);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(3);
			cell.setCellValue(msg);
			cell.setCellStyle(styleTestLogDetails(workbook));

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	
	
	
	/**
	 * 
	 * @param type
	 * @param msg
	 */
	private void createErrorLog(String type, String msg) {		
        try {        	
        	rowNum ++;
        	repRowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);   
			Row row = sheet.createRow(rowNum);
			
			Cell cell = row.createCell(0);
			cell.setCellValue(repRowNum);
			cell.setCellStyle(styleStepLog(workbook));
			
			cell = row.createCell(1);
			cell.setCellValue("FAIL");
			cell.setCellStyle(styleFailLog(workbook));
			
			cell = row.createCell(2);
			cell.setCellValue(type);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(3);
			cell.setCellValue(msg);
			cell.setCellStyle(styleTestLogDetails(workbook));

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	


	/**
	 * 
	 * @param type
	 * @param msg
	 */
	private void createWarningLog(String type, String msg) {		
        try {        	
        	rowNum ++;
        	repRowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);   
			Row row = sheet.createRow(rowNum);
			
			Cell cell = row.createCell(0);
			cell.setCellValue(repRowNum);
			cell.setCellStyle(styleStepLog(workbook));
			
			cell = row.createCell(1);
			cell.setCellValue("WARN");
			cell.setCellStyle(styleWarningLog(workbook));
			
			cell = row.createCell(2);
			cell.setCellValue(type);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(3);
			cell.setCellValue(msg);
			cell.setCellStyle(styleTestLogDetails(workbook));

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}
	
	
	/**
	 * 
	 */
	private void createTestSummaryLogs() {
        try {        	
        	sumRowNum++;
        	repSumRowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, summarySheetName);    		
			Row row = sheet.createRow(sumRowNum);
			
			Cell cell = row.createCell(0);
			cell.setCellValue(repSumRowNum);
			cell.setCellStyle(styleStepLog(workbook));
			
			cell = row.createCell(1);
			cell.setCellValue(dashboardName);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(2);
			cell.setCellValue(vizName);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(3);
			cell.setCellValue(successCounter);
			cell.setCellStyle(stylePassLog(workbook));
			
			cell = row.createCell(4);
			cell.setCellValue(errorCounter);
			if(errorCounter > 0)
				cell.setCellStyle(styleFailLog(workbook));
			else
				cell.setCellStyle(styleTestLogDetails(workbook));

			cell = row.createCell(5);
			cell.setCellValue(warningCounter);
			if(warningCounter > 0)
				cell.setCellStyle(styleWarningLog(workbook));
			else
				cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(6);
			cell.setCellValue(duration);
			cell.setCellStyle(styleTestLogDetails(workbook));
			
			cell = row.createCell(7);
			cell.setCellValue(sheetName);
			cell.setCellStyle(styleTestLogDetails(workbook));

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}
	
	
	/**
	 * 
	 * @throws ParseException
	 */
	private void createDetailSummaryFooter() throws ParseException {		
        try {        	
        	duration = testDuration();
        	rowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, sheetName);    	
    		String [][] testResults = new String [][] {  
	    	    {"","","Test Results", "*****"},    
	    	    {"","","End Time", getCurrentDateTime()},
	    	    {"","","Duration(hh:mm:ss)", duration},
	    	    {"","","Success", Integer.toString(successCounter)},
	    	    {"","","Error(s)", Integer.toString(errorCounter)},  
	    	    {"","","Warning(s)", Integer.toString(warningCounter)}
    		};
    	    
    	    for (int i = 0; i < testResults.length; i++) {
    			Row row = sheet.createRow(rowNum++);
    			for(int j = 0; j < testResults[i].length; j++) {
    				Cell cell = row.createCell(j);
    				if ((j == 3) && (i > 2))
    					cell.setCellValue(Integer.parseInt(testResults[i][j]));
    				else
        				cell.setCellValue(testResults[i][j]);
    				if (j < 2) 
    					cell.setCellStyle(styleTestLightGreyFill(workbook));
    				else 
    					cell.setCellStyle(styleTestDetails(workbook));
    			}
    	    }

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();	        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}		
	
	
	/**
	 * 
	 * @throws ParseException
	 */
	public void createTestSummaryFooter() throws ParseException {		
        try {       
        	sumRowNum++;
        	int sumrow = sumRowNum;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, summarySheetName); 
    		
	        Row row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("Test Suite Results");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,7));
    		Cell cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleFooterLabel(workbook));
    		
    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("End Time");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,1));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(getCurrentDateTime());
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,2,7));
    		cell = sheet.getRow(sumrow).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));

    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("Duration");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,1));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(getTotalDuration());
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,2,7));
    		cell = sheet.getRow(sumrow).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));    

    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("Success");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,1));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(suiteSuccessCounter);
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,2,7));
    		cell = sheet.getRow(sumrow).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));

    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("Error(s)");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,1));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(suiteErrorCounter);
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,2,7));
    		cell = sheet.getRow(sumrow).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));    		
    		
    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("Warning(s)");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,1));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleTestDetails(workbook));
    		
	        row.createCell(2).setCellValue(suiteWarningCounter);
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,2,7));
    		cell = sheet.getRow(sumrow).getCell(2);
    		cell.setCellStyle(styleTestDetails(workbook));	   
    		
    		sumrow++;
	        row = sheet.createRow(sumrow);
	        row.createCell(0).setCellValue("");
	        sheet.addMergedRegion(new CellRangeAddress(sumrow,sumrow,0,7));
    		cell = sheet.getRow(sumrow).getCell(0);
    		cell.setCellStyle(styleFooterLabel(workbook));
	        
    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();       
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}	

	
	/**
	 * 
	 * @throws ParseException
	 */
	private void createModuleSummaryFooter() throws ParseException {		
        try {        	
        	modSumRowNum++;
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, moduleSummarySheetName);    		
			Row row = sheet.createRow(modSumRowNum);
	        row.createCell(0).setCellValue("");
	        sheet.addMergedRegion(new CellRangeAddress(modSumRowNum,modSumRowNum,0,moduleReportCaption.size()-1));
	        Cell cell = sheet.getRow(modSumRowNum).getCell(0);
    		cell.setCellStyle(styleFooterLabel(workbook));

    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
			workbook.write(fos);
			fos.close();
			workbook.close();	        
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}		

	
	/**
	 * 
	 * @return
	 */
	public String getCurrentDateTime() {
       DateFormat df = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
       Calendar calobj = Calendar.getInstance();
       return df.format(calobj.getTime());
	}	

	
	/**
	 * 
	 * @return
	 */
	public String getCurrentDate() {
       DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
       Calendar calobj = Calendar.getInstance();
       return df.format(calobj.getTime());
	}

	
	/**
	 * 
	 * @return
	 */
	public String getCurrentTime() {
       DateFormat df = new SimpleDateFormat("HH:mm:ss");
       Calendar calobj = Calendar.getInstance();
       return df.format(calobj.getTime());
	}
	
	
	/**
	 * 
	 * @return
	 */
	public static String getReportDateFormat() {
       DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
       Calendar calobj = Calendar.getInstance();
       String temp[] = df.format(calobj.getTime()).split("\\/");
       return temp[0] + "_" + temp[1] + "_" + temp[2];
	}
	
	
	/**
	 * 
	 * @return
	 */
	private String getTotalDuration() {		
		long time = 0;
        for (String tmp : testDurationList){
            String[] arr = tmp.split(":");
            time += Integer.parseInt(arr[2]);
            time += 60 * Integer.parseInt(arr[1]);
            time += 3600 * Integer.parseInt(arr[0]);
        }

        long hh = time / 3600;
        time %= 3600;
        long mm = time / 60;
        time %= 60;
        long ss = time;
        return format(hh) + ":" + format(mm) + ":" + format(ss);		
	}
	
	
	/**
	 * 
	 * @param s
	 * @return
	 */
	private static String format(long s){
        if (s < 10) return "0" + s;
        else return "" + s;
    }
	
	
	/**
	 * 
	 * @param filePath
	 * @throws InterruptedException
	 */
	public void deleteFileIfExists(String filePath) throws InterruptedException {
		File file = new File(filePath);  
		if(file.exists()) {
			file.delete();
		}
	}
	
	
	/**
	 * 
	 * @param dashboard
	 * @return
	 */
	private String dashMap(String dashboard) {
		switch(dashboard) {
			case "Spend Management":  
				return "SM";
			case "GBLMP Spend/Budget Management":  
				return "GB_SBM";
			case "GBLMP Vendor Management":  
				return "GB_VM";
			case "Budget Management":  
				return "BM";
			case "Matter Inventory Management":  
				return "MIM";
			case "Operational Management":  
				return "OM";
			case "Rate Management":  
				return "RM";
			case "Timekeeper Management":  
				return "TM";
			case "Vendor Management":  
				return "VM";
			case "LegalVIEW BillAnalyzer":  
				return "LBA";
			case "Inventory Management":  
				return "IM";

		}
		return null;
	}
	
	
	/**
	 * 
	 * @param dashboard
	 * @param viz
	 * @throws ParseException
	 * @throws IOException 
	 */
	@SuppressWarnings("static-access")
	public void initTestReport(String dashboard, String viz) throws ParseException, IOException {
		sheetName = (dashMap(dashboard) + "_" + viz.replaceAll("\\s", ""));
		if (sheetName.length() > 30)
			sheetName = sheetName.substring(0, 30);
		
		dashboardName = dashboard;
		vizName = viz;
		createTestSummaryReportHeaderDetails();
		createTestSummaryReportHeader();
		if (base.getBooleanConfigData("executeRegression")) {
			if (!checkIfSheetExists(moduleSummarySheetName)) {
				moduleReportCaptionMap();
				createModuleSummaryReportHeader();			
			}
		}
		createDetailSummaryReportHeader();
		createDetailSummaryReportHeaderDetails();
    	rowNum = 4;
    	repRowNum = 0;
		successCounter = 0;
		errorCounter = 0;
		warningCounter = 0;
		testStartTime = getCurrentTime();
	}	
	
	
	/**
	 * 
	 * @throws InterruptedException
	 * @throws ParseException 
	 * @throws IOException 
	 */
	public void initSummaryReport() throws InterruptedException, ParseException, IOException {
		createFolderIfNotExists(Constants.reportPath);		
		deleteFileIfExists(Constants.repPath());
		createFolderIfNotExists(Constants.downloadPath);
		cleanDirectory(Constants.downloadPath);
    	sumRowNum = 5;
    	repSumRowNum = 0;
    	modSumRowNum = 1;
    	repModSumRowNum = 0;    			
    	suiteSuccessCounter = 0;
    	suiteErrorCounter = 0;
    	suiteWarningCounter = 0;
    	suiteStartDateTime = getCurrentDateTime();
	}	
	
	
	/**
	 * 
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public void createFolderIfNotExists(String path) throws InterruptedException, ParseException {
	    File directory = new File(path);
	    if (!directory.exists()){
	        directory.mkdir();
	    }
	}	

	
	/**
	 * 
	 * @param type
	 * @param msg
	 * @throws IOException
	 */
	public void success(String type, String msg) throws IOException {
		if (Base.getBooleanConfigData("needExcelLog")) {
			successCounter++;
			createSuccessLog(type, msg);			
		}
		if (Base.getBooleanConfigData("needConsoleLog")) {
			if (type.length()>=7)
				log.info("[" + type + "] " + msg);
			else
				log.info("[" + type + " ] " + msg);			
		}
	}
	
	
	/**
	 * 
	 * @param type
	 * @param msg
	 * @throws IOException
	 */
	public void error(String type, String msg) throws IOException {	
		Constants.moduleErrCounter++;
		if (Base.getBooleanConfigData("needExcelLog")) {
			errorCounter++;
			createErrorLog(type, msg);
		}
		if (Base.getBooleanConfigData("needConsoleLog")) {
			if (type.length()>=7)
				log.error("[" + type + "] " + msg);
			else
				log.error("[" + type + " ] " + msg);
		}
	}	
	
	
	/**
	 * 
	 * @param type
	 * @param msg
	 * @throws IOException
	 */
	public void warning(String type, String msg) throws IOException {	
		if (Base.getBooleanConfigData("needExcelLog")) {
			warningCounter++;
			createWarningLog(type, msg);
		}
		if (Base.getBooleanConfigData("needConsoleLog")) {
			if (type.length()>=7)
				log.warn("[" + type + "] " + msg);
			else
				log.warn("[" + type + " ] " + msg);
		}
	}	
	
	
	/**
	 * 
	 * @param type
	 * @param msg
	 * @throws IOException
	 */
	public void log(String type, String msg) throws IOException {	
		if (Base.getBooleanConfigData("needConsoleLog")) {
			if (type.length()>=7)
				log.error("[" + type + "] " + msg);
			else
				log.error("[" + type + " ] " + msg);
		}
	}	
	
	
	/**
	 * 
	 * @return
	 * @throws ParseException
	 */
	private String testDuration() throws ParseException {
		SimpleDateFormat format = new SimpleDateFormat("HH:mm:ss");
		Date date1 = format.parse(testStartTime);
		Date date2 = format.parse(getCurrentTime());
		long difference = date2.getTime() - date1.getTime(); 
		return DurationFormatUtils.formatDuration(difference, "HH:mm:ss");	
	}	
	
	
	/**
	 * 
	 * @throws ParseException
	 */
	public void updateReportResult() throws ParseException {
		suiteSuccessCounter += successCounter;
		suiteErrorCounter += errorCounter;
		suiteWarningCounter += warningCounter;
    	testDurationList.add(testDuration());
    	createDetailSummaryFooter();
    	createTestSummaryLogs();
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws InterruptedException
	 */
	public void cleanDirectory(String path) throws InterruptedException {
		for(File file: new java.io.File(path).listFiles()) {
		    if (!file.isDirectory()) 
		    	file.delete();
		}		
	}
	
	
	/**
	 * 
	 * @param path
	 * @throws InterruptedException
	 */	
	public void deleteDirectory(String path) throws InterruptedException {
	    File index = new File(Constants.downloadPath);
	    String[]entries = index.list();
	    for(String s: entries){
	        File currentFile = new File(index.getPath(),s);
	        currentFile.delete();
	    }
	    index.delete();
	}
	

	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws InterruptedException
	 * @throws ParseException 
	 * @throws IOException 
	 */
	public void beforeTest() throws InterruptedException, ParseException, IOException {
		initSummaryReport();
	}

	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws InterruptedException
	 * @throws ParseException 
	 * @throws IOException 
	 */
	public void afterTest() throws InterruptedException, ParseException, IOException {
		createTestSummaryFooter();
		
		if (!Base.getBooleanConfigData("executeFilters")) {
			if (!Constants.errFlag)createModuleSummaryFooter();			
		}
		deleteDirectory(Constants.downloadPath);
	}
	
	
	/**
	 * 
	 * @param moduleRepDashboardName
	 * @param baseLevelVizName
	 * @param FirstLevelVizName
	 * @param SecondLevelVizName
	 * @throws InterruptedException
	 * @throws ParseException
	 * @throws IOException
	 */
	public void updateModuleReportDashViz(String moduleRepDashboardName, String baseLevelVizName, String FirstLevelVizName, String SecondLevelVizName) throws InterruptedException, ParseException, IOException {
		modSumRowNum++;
		repModSumRowNum++;
		tempFirstVizName = FirstLevelVizName;
		tempSecondVizName = SecondLevelVizName;
		updateModuleSummaryLogs("Step", Integer.toString(repModSumRowNum));
		updateModuleSummaryLogs("Dashboard", moduleRepDashboardName);
		updateModuleSummaryLogs("BaseLevelVizName", baseLevelVizName);
		if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
			updateModuleSummaryLogs("FirstLevelVizName", FirstLevelVizName);
		}
		if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
			updateModuleSummaryLogs("FirstLevelVizName", FirstLevelVizName);
			updateModuleSummaryLogs("SecondLevelVizName", SecondLevelVizName);
		}
		if ((!tempFirstVizName.equalsIgnoreCase("NA") &&  tempSecondVizName.equalsIgnoreCase("NA")) || (!tempFirstVizName.equalsIgnoreCase("NA") && !tempSecondVizName.equalsIgnoreCase("NA"))) {
			updateModuleSummaryLogs("AppLaunchSteps", "NA");
			if (Base.getBooleanConfigData("needContextualCheck")) {
				updateModuleSummaryLogs("ContextualMenuSteps", "NA");
			}
			updateModuleSummaryLogs("SetDefaultFilterSteps", "NA");
			updateModuleSummaryLogs("GetVizSteps", "NA");
			if (Base.getBooleanConfigData("needExportAllCSV")) {
				updateModuleSummaryLogs("ExportAllCSVSteps", "NA");
			}
		}
		if (tempFirstVizName.equalsIgnoreCase("NA") && tempSecondVizName.equalsIgnoreCase("NA")) {
			if ((Base.getBooleanConfigData("needFirstLevelDrillChecks") && Base.getBooleanConfigData("needSecondLevelDrillChecks")) || (Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks"))) {
				updateModuleSummaryLogs("DrillDownMenuValidationSteps", "NA");
				if (Base.getBooleanConfigData("needPrintPreviewCheck")) {
					updateModuleSummaryLogs("PrintPreviewSteps", "NA");
				}
				updateModuleSummaryLogs("BreadCrumbNavigationSteps", "NA");
			}			
		}
	}
	
	
	/**
	 * 
	 */
	public void updateModuleReportAppLaunchSteps() throws ParseException {
		if (tempFirstVizName.equalsIgnoreCase("NA") && tempSecondVizName.equalsIgnoreCase("NA")) {
			if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("AppLaunchSteps", "FAIL");
			else updateModuleSummaryLogs("AppLaunchSteps", "PASS");		
		} else {
			updateModuleSummaryLogs("AppLaunchSteps", "NA");
		}
	}
	
	
	/**
	 * @throws IOException 
	 * 
	 */
	public void updateModuleReportContextualMenuSteps() throws ParseException, IOException {
		if (tempFirstVizName.equalsIgnoreCase("NA") && tempSecondVizName.equalsIgnoreCase("NA")) {
			if (Base.getBooleanConfigData("needContextualCheck")) {
				if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("ContextualMenuSteps", "FAIL");
				else updateModuleSummaryLogs("ContextualMenuSteps", "PASS");
			}
		} else {
			updateModuleSummaryLogs("ContextualMenuSteps", "NA");
		}
	}
	
	
	/**
	 * 
	 */
	public void updateModuleReportSetDefaultFilterSteps() throws ParseException {
		if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("SetDefaultFilterSteps", "FAIL");
		else updateModuleSummaryLogs("SetDefaultFilterSteps", "PASS");
	}
	
	
	/**
	 * 
	 */
	public void updateModuleReportGetVizSteps() throws ParseException {
		if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("GetVizSteps", "FAIL");
		else updateModuleSummaryLogs("GetVizSteps", "PASS");
	}
	
	
	/**
	 * 
	 */
	public void updateModuleReportVizViewSteps() throws ParseException {
		if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("VizViewSteps", "FAIL");
		else updateModuleSummaryLogs("VizViewSteps", "PASS");
	}
	

	/**
	 * @throws IOException 
	 * 
	 */
	public void updateModuleReportExportAllCSVSteps() throws InterruptedException, ParseException, IOException {
		if (tempFirstVizName.equalsIgnoreCase("NA") && tempSecondVizName.equalsIgnoreCase("NA")) {
			if (Base.getBooleanConfigData("needExportAllCSV")) {
				if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("ExportAllCSVSteps", "FAIL");
				else updateModuleSummaryLogs("ExportAllCSVSteps", "PASS");
			}
		}
	}
	
	
	/**
	 * @throws IOException 
	 * 
	 */
	public void updateModuleReportDataValidationSteps() throws InterruptedException, ParseException, IOException {
		if (Base.getBooleanConfigData("needDataValidationCheck")) {
			if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("DataValidationSteps", "FAIL");
			else updateModuleSummaryLogs("DataValidationSteps", "PASS");
		}
	}
	
	
	/**
	 * 
	 */
	public void updateModuleReportDrillDownMenuValidationSteps() throws ParseException {
		if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("DrillDownMenuValidationSteps", "FAIL");
		else updateModuleSummaryLogs("DrillDownMenuValidationSteps", "PASS");
	}
	
	
	/**
	 * @throws IOException 
	 * 
	 */
	public void updateModuleReportPrintPreviewSteps() throws InterruptedException, ParseException, IOException {
		if (Base.getBooleanConfigData("needPrintPreviewCheck")) {
			if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("PrintPreviewSteps", "FAIL");
			else updateModuleSummaryLogs("PrintPreviewSteps", "PASS");
		}
	}	
	
	
	/**
	 * 
	 */
	public void updateModuleReportBreadCrumbNavigationSteps() throws ParseException {
		if (Constants.moduleErrCounter > 0) updateModuleSummaryLogs("BreadCrumbNavigationSteps", "FAIL");
		else updateModuleSummaryLogs("BreadCrumbNavigationSteps", "PASS");
	}
	
	
	
	/**
	 * @throws IOException 
	 * 
	 */	
	public void moduleReportCaptionMap() throws IOException {
		moduleReportCaption.add("Step");		
		moduleReportCaption.add("Dashboard");
		moduleReportCaption.add("BaseLevelVizName");		
		if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
			moduleReportCaption.add("FirstLevelVizName");
		}
		if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
			moduleReportCaption.add("FirstLevelVizName");
			moduleReportCaption.add("SecondLevelVizName");
		}
		moduleReportCaption.add("AppLaunchSteps");
		if (Base.getBooleanConfigData("needContextualCheck")) {
			moduleReportCaption.add("ContextualMenuSteps");
		}
		moduleReportCaption.add("SetDefaultFilterSteps");
		moduleReportCaption.add("GetVizSteps");
		moduleReportCaption.add("VizViewSteps");
		if (Base.getBooleanConfigData("needExportAllCSV")) {
			moduleReportCaption.add("ExportAllCSVSteps");
		}
		if (Base.getBooleanConfigData("needDataValidationCheck")) {
			moduleReportCaption.add("DataValidationSteps");
		}
		if ((Base.getBooleanConfigData("needFirstLevelDrillChecks") && Base.getBooleanConfigData("needSecondLevelDrillChecks")) || (Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks"))) {
			moduleReportCaption.add("DrillDownMenuValidationSteps"); 
			if (Base.getBooleanConfigData("needPrintPreviewCheck")) {
				moduleReportCaption.add("PrintPreviewSteps");
			}
			moduleReportCaption.add("BreadCrumbNavigationSteps");
		}		
	}	
	
	
	/**
	 * 
	 * @param caption
	 * @param rowNum
	 * @return
	 */
	private int getCellNum(String caption, int rowNum) {
        try {       
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, moduleSummarySheetName);    		
			Row row = sheet.getRow(rowNum);
			Iterator<Cell> cell= row.cellIterator();
			int column = 0;
			while(cell.hasNext()) {
				Cell colVal = cell.next();
				if(colVal.getStringCellValue().equalsIgnoreCase(caption)){
					//System.out.println(colVal.getStringCellValue());
					workbook.close();
					return column;
				}				
				column++;
			}				

	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
		return 0;
	}
	
	
	/**
	 * 
	 * @param caption
	 * @param rowNum
	 * @return
	 */
	private boolean checkIfColumnExists(String caption, int rowNum) {
        try {       
    		XSSFWorkbook workbook = getXLWorkbook();
    		Sheet sheet = getXLSheet(workbook, moduleSummarySheetName);    		
			Row row = sheet.getRow(rowNum);
			Iterator<Cell> cell= row.cellIterator();
			while(cell.hasNext()) {
				Cell colVal = cell.next();
				if(colVal.getStringCellValue().equalsIgnoreCase(caption)){
					//System.out.println(colVal.getStringCellValue());
					workbook.close();
					return true;
				}				
			}				

	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
		return false;
	}
	
	
	/**
	 * 
	 * @param sheetName
	 * @return
	 */
	private boolean checkIfSheetExists(String sheetName) {
        try {       
    		XSSFWorkbook workbook = getXLWorkbook(); 
    		if (workbook.getNumberOfSheets() != 0) {
    	        for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
    	           if (workbook.getSheetName(i).equals(sheetName)) {
    	   				workbook.close();
    	   				return true;
    	            }
    	        }
    	    }
			workbook.close();
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
		return false;
	}
	

	/**
	 * 
	 * @param caption
	 * @param data
	 */
	public void updateModuleSummaryLogs(String caption, String data) {
        try {
        	if (checkIfColumnExists(caption, 1)) {
	        	int freezeRowCounter = 2000;
				Row row;
	        	int cellNum = getCellNum(caption, 1);
	    		XSSFWorkbook workbook = getXLWorkbook();
	    		Sheet sheet = getXLSheet(workbook, moduleSummarySheetName);   
	    		if (caption.equalsIgnoreCase("step")) {
	    			row = sheet.createRow(modSumRowNum);
	    		} else {
	    			row = sheet.getRow(modSumRowNum);
	    		}
				
				Cell cell = row.createCell(cellNum);
				if (caption.equalsIgnoreCase("step")) {
					cell.setCellValue(Integer.parseInt(data));
					cell.setCellStyle(styleStepLog(workbook));
				}
				else {
					cell.setCellValue(data);
					if (data.equalsIgnoreCase("pass")) cell.setCellStyle(stylePassLog(workbook));
					else if (data.equalsIgnoreCase("fail")) cell.setCellStyle(styleFailLog(workbook));
					else if (data.equalsIgnoreCase("na")) cell.setCellStyle(styleNALog(workbook));
					else if (data.equalsIgnoreCase("off")) cell.setCellStyle(styleWarningLog(workbook));
					else {
						cell.setCellStyle(styleTestLogDetails(workbook));
					}
				}
	
				if (!Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
					sheet.createFreezePane(3, freezeRowCounter);
				}
				if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && !Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
					sheet.createFreezePane(4, freezeRowCounter);
				}
				if (Base.getBooleanConfigData("needFirstLevelDrillChecks") && Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
					sheet.createFreezePane(5, freezeRowCounter);
				}
	
	    		FileOutputStream fos = new FileOutputStream(Constants.repPath());
				workbook.write(fos);
				fos.close();
				workbook.close();
        	}
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}

}
