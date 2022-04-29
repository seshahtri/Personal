package common;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.LinkedHashMap;

public class CsvHandlers {
	
	String regEx;
	Report report;
	public CsvHandlers() throws IOException {
		this.report = new Report();
		regEx = ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)";
	}	
	
	/**
	 * readTestPlan
	 * @param filePath
	 * @return arrayData
	 * @throws IOException
	 */
	
	@SuppressWarnings("resource")
	public ArrayList<LinkedHashMap<String, String>> readTestPlan(String filePath) throws IOException {
	    try {
	    	ArrayList<LinkedHashMap<String, String>> result = new ArrayList<LinkedHashMap<String, String>>();
		    int counter = 0;
			String[] header = null;
			String[] data = null;
			BufferedReader br = null;
			String nextLine = "";		
			br = new BufferedReader(new InputStreamReader(new FileInputStream(filePath), "UTF-8"));
            while ((nextLine = br.readLine()) != null) {    
    			LinkedHashMap<String, String> map = new LinkedHashMap<String, String>();
    			if (counter == 0) {
    				header = nextLine.split(regEx, -1);
    			} 
    			else {
    				data = nextLine.split(regEx, -1);
			    	for (int index=0; index<data.length; index++) {
			    		map.put(header[index], data[index]);
			    	}
			    	result.add(map);
    			}
		    	counter++;
		    }	
            //printArrayData(result,1);
	        return result;
	    } catch (Exception e) {
	    	report.error("Action", "[CSV Reader] CSV file read exception (" + e.getMessage() + ")");
	    }
		return null;
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 */
	public String vizMap(String vizName) {
		switch(vizName) {
			case "Number of Billing Attorneys Top Biller by Firm":  
				return "Number of Billing Attorneys, Top Biller by Firm";
		}
		return null;
	}	

}
