({
    init : function(component, event, helper) {
        let action = component.get("c.getStoredReport");
        var recIdfromVf = component.get("v.recordIdFromVf");
        var recordIdComp;
        if(!recIdfromVf){
            console.log("yyyyy");
            recordIdComp = component.get("v.recordId");
        }else{
            console.log("xxxxxx");
            recordIdComp = recIdfromVf;
        }
        
        console.log(recIdfromVf  + ")))" + recordIdComp);
        action.setParams({
            reportId: recordIdComp
        });
        action.setCallback(this, function (result) {
            let state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                let resultData = JSON.parse(result.getReturnValue());
                console.log(resultData);
                component.set('v.triggerAnalyzerReport', resultData);
                component.set('v.selectedObject', resultData[0]);
            }
        });
        $A.enqueueAction(action);
    },
    objectNameClickHandler: function(component, event, helper) {
        let selectedVal = event.currentTarget.dataset.value;
        let selectedObject = component.get('v.triggerAnalyzerReport').filter(x => x.objectApiName === selectedVal);
        component.set('v.selectedObject', selectedObject[0] ? selectedObject[0] : component.get('v.triggerAnalyzerReport')[0]);
    },
    handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');

        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },
    onmousehover : function(component, event, helper) {
        console.log('=onmousehover===');
        component.set('v.isTooltip', true);
    }
})