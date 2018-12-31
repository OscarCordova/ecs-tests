import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class MTax implements Constant {
    
    public MTax(){
        
    }
    
    public static List<String> validateTaxes(List<XTax> xTaxList) {
        
        List<String> errorList = new ArrayList<>();
        List<String> taxCategoryList = MInfoTaxCategory.getTaxCategoryStringList();

        if (xTaxList == null) {
            errorList.add("The document has not taxes.");
            return errorList;    
        }

        boolean noLocalTax = false;
        for (XTax tax : xTaxList) {
            // Validate if the id exists
            if (tax.getId() != null) {
                tax.setCreated(tax.getId().toString().getCreated());
            }
            // Validate if the amount is not null
            if (tax.getAmount() == null) {
               errorList.add("The amount must be not null.");
            }
            // Validate if the thax is not null
            if (taxObj.getTax() == null) {
                errorList.add("The tax must be not null.");
            }
            // Validate if the tax is a valid record according to the
            // given tax category list 
            if (!taxCategoryList.contains(tax)) {
                errorList.add("The tax is not a valid tax.");
            }
            // If the tax is a local tax validate if the tax is not null
            if (tax.getTaxAmount() == null ) {
                errorList.add("The tax amount is required.");
            }
            // Only set True if the tax is not local and the flag variable is False
            if (!tax.isLocal() && !noLocalTax){
                noLocalTax = true;
            }
        }
        // Validate if there any no local tax
        if (!noLocalTax) {
            errorList.add("Debe de incluir al menos una tasa no local");
        }
        return errorList;
    }
}
