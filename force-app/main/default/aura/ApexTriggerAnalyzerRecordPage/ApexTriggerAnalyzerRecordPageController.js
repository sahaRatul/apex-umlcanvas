({
    init : function(component, event, helper) {
        let action = component.get("c.getStoredReport");
        action.setParams({
            reportId: component.get('v.recordId')
        });
        action.setCallback(this, function (result) {
            let state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                let resultData = JSON.parse(result.getReturnValue());
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
    }
})
