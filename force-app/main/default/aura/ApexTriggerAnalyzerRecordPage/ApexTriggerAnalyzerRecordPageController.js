({
    init : function(component, event, helper) {
        let dummyData = helper.getDummyData();
        component.set('v.triggerAnalyzerReport', dummyData);
        component.set('v.selectedObject', dummyData[0]);
    },
    objectNameClickHandler: function(component, event, helper) {
        let selectedVal = event.currentTarget.dataset.value;
        let selectedObject = component.get('v.triggerAnalyzerReport').filter(x => x.objectApiName === selectedVal);
        component.set('v.selectedObject', selectedObject[0] ? selectedObject[0] : component.get('v.triggerAnalyzerReport')[0]);
    }
})
