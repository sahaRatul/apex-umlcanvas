({
    init: function (component, event, helper) {
        let action = component.get("c.getStoredReport");
        var recIdfromVf = component.get("v.recordIdFromVf");
        var recordIdComp;
        if (!recIdfromVf) {
            recordIdComp = component.get("v.recordId");
        } else {
            recordIdComp = recIdfromVf;
        }

        action.setParams({
            reportId: recordIdComp
        });
        action.setCallback(this, function (result) {
            let state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                let resultData = JSON.parse(result.getReturnValue());
                let accounts = resultData.map(x => x.objectApiName);

                component.set('v.triggerAnalyzerReport', resultData);
                component.set('v.selectedObject', resultData[0]);

                let action2 = component.get("c.getApexTriggerListWithIds");
                action2.setParams({
                    objectNames: accounts
                });
                action2.setCallback(this, function (result2) {
                    if (component.isValid() && state === "SUCCESS") {
                        let resultData2 = result2.getReturnValue();
                        component.set('v.triggerIdList', resultData2);
                    }
                });
                $A.enqueueAction(action2);
            }
        });
        $A.enqueueAction(action);
    },
    triggerNameClickHandler: function (component, event, helper) {
        event.preventDefault();
        let elem = event.currentTarget;
        let triggerName = elem.getAttribute("data-trigger-name");
        let triggerNameIdList = component.get('v.triggerIdList');

        let selectedTrigger = triggerNameIdList.filter(x => x.Name === triggerName)[0];

        let navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": selectedTrigger.Id,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    navigateToRecord: function (component, event, helper) {
        window.open('/' + event.getParam('recordId'));
    },
    objectNameClickHandler: function (component, event, helper) {
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
    onmousehover: function (component, event, helper) {
        console.log('=onmousehover===');
        component.set('v.isTooltip', true);
    }
})