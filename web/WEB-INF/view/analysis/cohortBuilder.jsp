<%@ include file="/WEB-INF/template/include.jsp" %>

<openmrs:require privilege="View Patient Sets" otherwise="/login.htm" redirect="/cohortBuilder.list" />

<c:set var="OPENMRS_DO_NOT_SHOW_PATIENT_SET" scope="request" value="true"/>

<%@ include file="/WEB-INF/template/header.jsp" %>

<script type="text/javascript" src='<%= request.getContextPath() %>/dwr/engine.js'></script>
<script type="text/javascript" src='<%= request.getContextPath() %>/dwr/util.js'></script>
<script type="text/javascript" src='<%= request.getContextPath() %>/dwr/interface/DWRCohortBuilderService.js'></script>
<script type="text/javascript" src='<%= request.getContextPath() %>/dwr/interface/DWRPatientService.js'></script>
<script type="text/javascript" src='<%= request.getContextPath() %>/dwr/interface/DWRPatientSetService.js'></script>
<openmrs:htmlInclude file="/dwr/interface/DWRProgramWorkflowService.js" />
<openmrs:htmlInclude file="/scripts/dojoConfig.js"></openmrs:htmlInclude>
<openmrs:htmlInclude file="/scripts/dojo/dojo.js"></openmrs:htmlInclude>
<openmrs:htmlInclude file="/scripts/calendar/calendar.js" />

<openmrs:globalProperty var="SHOW_LAST_N" defaultValue="5" key="cohort.cohortBuilder.showLastSearches"/>

<script type="text/javascript">
	dojo.require("dojo.widget.openmrs.ConceptSearch");
	dojo.hostenv.writeIncludes();
	
	dojo.addOnLoad( function() {
		dojo.event.topic.subscribe("concept_to_filter_search/select", 
			function(msg) {
				if (msg) {
					var concept = msg.objs[0];
					showPossibleFilters(concept);
				}
			}
		);
	})
	
	// tab ids should be searchTab_concept
	// tab content ids should be searchTab_concept_content
	function changeSearchTab(tabObj) {
		if (typeof tabObj == 'string')
			tabObj = document.getElementById(tabObj);

		if (tabObj) {
			var tabs = tabObj.parentNode.parentNode.getElementsByTagName('a');
			for (var i = 0; i < tabs.length; ++i) {
				if (tabs[i].className.indexOf('current') != -1) {
					manipulateClass('remove', tabs[i], 'current');
				}
				var tabContentId = tabs[i].id + '_content';
				if (tabs[i].id == tabObj.id)
					showLayer(tabContentId);
				else
					hideLayer(tabContentId);
			}
			addClass(tabObj, 'current');
		}
	}
	
	function classFilterTemplate(concept) {
		if (concept.className == 'Program') {
			var str = '<form method="post" action="cohortBuilder.form">';
			str += '<input type="hidden" name="method" value="addDynamicFilter"/>';
			str += '<input type="hidden" name="filterClass" value="org.openmrs.reporting.ProgramPatientFilter" />';
			str += '<input type="hidden" name="vars" value="program#org.openmrs.Program,fromDate#java.util.Date,toDate#java.util.Date"/>';
			str += '<input type="hidden" name="program" value="concept.' + concept.conceptId + '"/>';
			str += 'In ' + concept.name;
			str += ' <input type="submit" value="Search"/>';
			str += '</form>';			
			return str;
		} else if (concept.className == 'State' || concept.className == 'Workflow')
			return 'Workflow/State filter not yet implemented';
		else if (concept.className == 'Drug') {
			var str = '<form method="post" action="cohortBuilder.form">';
			str += '<input type="hidden" name="method" value="addDynamicFilter"/>';
			str += '<input type="hidden" name="filterClass" value="org.openmrs.reporting.DrugOrderPatientFilter" />';
			str += '<input type="hidden" name="vars" value="groupMethod#org.openmrs.api.PatientSetService$GroupMethod,drugConcept#org.openmrs.Concept"/>';
			str += '<select name="groupMethod"><option value="">Taking ' + concept.name + '</option><option value="NONE">Taking nothing</option></select>';
			str += '<input type="hidden" name="drugConcept" value="' + concept.conceptId + '"/>';
			str += ' <input type="submit" value="Search"/>';
			str += '</form>';			
			return str;
		}
		return null;
	}
	
	function obsFilterTemplate(concept) {
		var hl7Abbrev = concept.hl7Abbreviation;
		if (hl7Abbrev == 'ZZ')
			//return 'Handling Datatype N/A not yet implemented. Any suggestions on how it should behave?';
			return null;
		if (hl7Abbrev != 'NM' && hl7Abbrev != 'ST' && hl7Abbrev != 'CWE') {
			return null;
		}
		var lookupAnswers = false;
		var str = '<form method="post" action="cohortBuilder.form">';
		str += '<input type="hidden" name="method" value="addDynamicFilter"/>';
		str += '<input type="hidden" name="filterClass" value="org.openmrs.reporting.ObsPatientFilter" />';
		str += '<input type="hidden" name="vars" value="timeModifier#org.openmrs.api.PatientSetService$TimeModifier,question#org.openmrs.Concept,modifier#org.openmrs.api.PatientSetService$Modifier,';
		if (hl7Abbrev == 'CWE')
			str += 'value#org.openmrs.Concept';
		else
			str += 'value#java.lang.Object';
		str += ',withinLastMonths#java.lang.Integer,withinLastDays#java.lang.Integer,sinceDate#java.util.Date,untilDate#java.util.Date"/>';
		if (hl7Abbrev == 'NM')
			str += '<select name="timeModifier"><option value="ANY">ANY</option><option value="NO">NO</option><option value="FIRST">FIRST</option><option value="LAST">LAST</option><option value="MIN">MIN</option><option value="MAX">MAX</option><option value="AVG">AVG</option></select> ';
		else if (hl7Abbrev == 'ST' || hl7Abbrev == 'CWE')
			str += '<select name="timeModifier"><option value="ANY">ANY</option><option value="NO">NO</option><option value="FIRST">FIRST</option><option value="LAST">LAST</option></select> ';
		str += '<input type="hidden" name="question" value="' + concept.conceptId + '"/>';
		str += concept.name;
		if (hl7Abbrev == 'NM') {
			str += ' <br/><br/><span style="margin-left: 40px">';
			str += ' (optional value constraint)';
			str += ' <select name="modifier" id="modifier"><option value="LESS_THAN">&lt;</option><option value="LESS_EQUAL">&lt;=</option><option value="EQUAL">=</option><option value="GREATER_EQUAL">&gt;=</option><option value="GREATER_THAN">&gt;</option></select> ';
			str += '</span>';
		} else if (hl7Abbrev == 'ST' || hl7Abbrev == 'CWE') {
			str += ' is ';
			str += '<input type="hidden" name="modifier" value="EQUAL" /> ';
		}
		if (hl7Abbrev == 'NM' || hl7Abbrev == 'ST')
			str += '<input type="text" name="value" size="10"/>';
		else if (hl7Abbrev == 'CWE') {
			str += '<select name="value" id="replace_with_answer_options"><option value="">Loading...</option></select>';
			lookupAnswers = true;
		}
		str += ' <br/><br/><span style="margin-left: 40px">';
		str += ' (optional time constraint) within the last ';
		str += ' <input type="text" name="withinLastMonths" value="" size="2" />';
		str += ' months and/or';
		str += ' <input type="text" name="withinLastDays" value="" size="2" />';
		str += ' days';
		str += '</span>';
		str += ' <br/><br/><span style="margin-left: 40px">';
		str += ' (optional date constraint) since ';
		str += ' <input type="text" name="sinceDate" size="10" value="" onClick="showCalendar(this)" />';
		str += ' until ';
		str += ' <input type="text" name="untilDate" size="10" value="" onClick="showCalendar(this)" />';
		str += '</span>';
		str += ' <br/><br/><input type="submit" value="Search"/>';
		str += ' &nbsp;&nbsp;&nbsp;&nbsp;<input type="button" value="<spring:message code="general.cancel" />" onClick="hideLayer(\'concept_filter_box\')"/>';
		str += '</form>';
		if (lookupAnswers) {
			DWRConceptService.getAnswersForQuestion(concept.conceptId, function(list) {
					DWRUtil.removeAllOptions('replace_with_answer_options');
					DWRUtil.addOptions('replace_with_answer_options', [" "]);
					DWRUtil.addOptions('replace_with_answer_options', list, 'conceptId', 'name');
				});
		}
		return str;
	}
	
	function obsValueFilterTemplate(concept) {
		var str = '<form method="post" action="cohortBuilder.form">';
		str += '<input type="hidden" name="method" value="addDynamicFilter"/>';
		str += '<input type="hidden" name="filterClass" value="org.openmrs.reporting.ObsPatientFilter" />';
		str += '<input type="hidden" name="vars" value="timeModifier#org.openmrs.api.PatientSetService$TimeModifier,modifier#org.openmrs.api.PatientSetService$Modifier,value#org.openmrs.Concept,withinLastMonths#java.lang.Integer,withinLastDays#java.lang.Integer,sinceDate#java.util.Date,untilDate#java.util.Date"/>';
		str += '<select name="timeModifier"><option value="ANY">ANY</option><option value="NO">NO</option></select> ';
		str += ' observation whose value is ';
		str += '<input type="hidden" name="modifier" value="EQUAL" /> ';
		str += '<input type="hidden" name="value" value="' + concept.conceptId + '"/>';
		str += concept.name;
		str += ' <br/><br/><span style="margin-left: 40px">';
		str += ' (optional time constraint) within the last ';
		str += ' <input type="text" name="withinLastMonths" value="" size="2" />';
		str += ' months and/or';
		str += ' <input type="text" name="withinLastDays" value="" size="2" />';
		str += ' days';
		str += '</span>';
		str += ' <br/><br/><span style="margin-left: 40px">';
		str += ' (optional date constraint) since ';
		str += ' <input type="text" name="sinceDate" size="10" value="" onClick="showCalendar(this)" />';
		str += ' until ';
		str += ' <input type="text" name="untilDate" size="10" value="" onClick="showCalendar(this)" />';
		str += '</span>';
		str += ' <br/><br/><input type="submit" value="Search"/>';
		str += ' &nbsp;&nbsp;&nbsp;&nbsp;<input type="button" value="<spring:message code="general.cancel" />" onClick="hideLayer(\'concept_filter_box\')"/>';
		str += '</form>';
		return str;
	}
	
	function possibleFilterHelper(filter) {
		return '<div style="background: #e0e0e0; border: 1px #808080 solid; padding: 0.5em; margin: 0.5em">' + filter + '</div>';
	}
		
	function showPossibleFilters(concept) {
		var div = document.getElementById('concept_filter_box');
		var str = '';
		var filter = obsFilterTemplate(concept);
		if (filter != null)
			str += possibleFilterHelper(filter);
		filter = classFilterTemplate(concept);
		if (filter != null)
			str += possibleFilterHelper(filter);
		filter = obsValueFilterTemplate(concept);
		if (filter != null)
			str += possibleFilterHelper(filter);
		
		div.innerHTML = str;
		showLayer('concept_filter_box');
	}
	
	function handleSaveCohort() {
		if (currentPatientSet == null) {
			window.alert("<spring:message code="PatientSet.stillLoading"/>");
			return;
		} else {
			var cohortName = $('saveCohortName').value;
			var cohortDescr = $('saveCohortDescription').value;
			var ids = currentPatientSet.commaSeparatedPatientIds;
			DWRCohortBuilderService.saveCohort(cohortName, cohortDescr, ids);
			hideLayer('saveCohortDiv');
		}		
	}
	
	function handleLoadButton() {
		if ($('loadBox').style.display == 'none') {
			hideLayer('saveBox');
			DWRCohortBuilderService.getSearchHistories(function(histories) {
					var loadBox = $('loadBox');
					loadBox.innerHTML = '';
					if (histories.length == 0)
						loadBox.innerHTML = '<spring:message javaScriptEscape="true" code="CohortBuilder.searchHistory.load.none"/>';
					else {
						var str = '<h4><u><spring:message javaScriptEscape="true" code="CohortBuilder.searchHistory.load"/></u></h4>';
						str += '<ul>';
						for (var i = 0; i < histories.length; ++i) {
							str += '<li><a href="javascript:loadSearchHistory(' + histories[i].id + ')">' + histories[i].name + ' <small>(' + histories[i].description + ')</small></a></li>';
						}
						str += '</ul>';
						str += '<input type="button" value="<spring:message code="general.cancel"/>" onClick="hideLayer(\'loadBox\')"/>';
						loadBox.innerHTML = str;
					}
					showLayer('loadBox');
				});
		} else {
			hideLayer('loadBox');
		}
	}
	
	function loadSearchHistory(id) {
		DWRCohortBuilderService.loadSearchHistory(id, function() { refreshPage(); });
	}
	
	function linkSubmitHelper(idPrefix) {
		if (currentPatientSet != null) {
			document.getElementById(idPrefix + "_ptIds").value = currentPatientSet.commaSeparatedPatientIds;
			document.getElementById(idPrefix + "_form").submit();
			hideLayer('_linkMenu');
		} else {
			window.alert("<spring:message code="PatientSet.stillLoading"/>");
		}
	}
	
	function showSaveFilterDialog(index, name) {
		var tempName = '#' + (index + 1);
		if (name != null && name != '')
			tempName += ' (<i>' + name + '</i>)';
		$('saveFilterTitle').innerHTML = tempName;
		$('saveFilterIndex').value = index;
		$('saveFilterName').value = '';
		$('saveFilterDescription').value = '';
		$('saveFilterSaveButton').style.disabled = 'false';
		$('saveFilterCancelButton').style.disabled = 'false';
		showLayer('saveFilterBox');
		$('saveFilterName').focus();
	}
	
	function handleSavedFilterMenuButton() {
		if ($('saved_filters').style.display == 'none') {
			$('saved_filters').innerHTML = 'Loading...';
			showLayer('saved_filters');
			DWRCohortBuilderService.getSavedFilters(function(filters) {
					var str = '<ul>';
					if (filters.length == 0)
						str = 'None';
					else {
						for (var i = 0; i < filters.length; ++i) {
							str += '<li><a href="cohortBuilder.form?method=addFilter&filter_id=' + filters[i].id + '">' + filters[i].name + ' <small>(' + filters[i].description + ')</small></a></li>';
						}
						str += '</ul>';
					}
					$('saved_filters').innerHTML = str;
					showLayer('saved_filters');
				});
		} else {
			hideLayer('saved_filters');
		}
	}
	
	function handleSaveFilter() {
		var index = $('saveFilterIndex').value;
		var name = $('saveFilterName').value;
		var descr = $('saveFilterDescription').value;
		$('saveFilterSaveButton').style.disabled = 'true';
		$('saveFilterCancelButton').style.disabled = 'true';
		DWRCohortBuilderService.saveHistoryElement(name, descr, index, function(success) {
				if (success) {
					window.alert('Saved #' + (index + 1) + ' as &quot;' + name + '&quot;');
				} else {
					window.alert('Failed to save.');
				}
				$('saveFilterSaveButton').style.disabled = 'false';
				$('saveFilterCancelButton').style.disabled = 'false';
				hideLayer('saveFilterBox');
			});
	}
	
	function refreshWorkflowOptions() {
		var program = DWRUtil.getValue('program');
		if (program == null || program == '')
			DWRUtil.removeAllOptions('workflow');
		else
			DWRProgramWorkflowService.getWorkflowsByProgram(program, function(wfs) {
					DWRUtil.removeAllOptions('workflow');
					DWRUtil.addOptions('workflow', [" "]);
					DWRUtil.addOptions('workflow', wfs, 'id', 'name');
					refreshStateOptions();
				});
	}
	
	function refreshStateOptions() {
		var workflow = DWRUtil.getValue('workflow');
		if (workflow == null) {
			DWRUtil.removeAllOptions('state');
		} else
			DWRProgramWorkflowService.getStatesByWorkflow(workflow, function (states) {
					DWRUtil.removeAllOptions('state');
					DWRUtil.addOptions('state', [" "]);
					DWRUtil.addOptions('state', states, 'id', 'name');
				});
	}
	
</script>

<script type="text/javascript">
	<%--
	This doesn't work yet, because there are no converters for patient filters
	function refreshHistory() {
		var div = document.getElementById('cohort_builder_search_history');
		div.innerHTML = 'Loading...';
		DWRCohortBuilderService.getUserSearchHistory(function(csh) {
				var str = '<ol>';
				var searches = csh.items;
				var numSearches = searches.length;
				for (var i = 0; i < numSearches; ++i) {
					var search = searches[i];
					var filter = search.filter;
					var result = search.cachedResult;
					str += '<li>' + filter.name + ' <small>(' + filter.description + ')</small>';
					if (result != null)
						str += ' (' + result.size + ' <spring:message code="CohortBuilder.numResults"/>)';
					str += '</li>';
				}
				str += '</ol>';
				div.innerHTML = 'testing: ' + str;
			});
	}
	--%>
	
	function previewPageTo(index) {
		if (index < 0)
			index = currentPatientSet.size - patientPageSize;
		fromPatientIndex = index;
		refreshPreview();
	}
	
	function previewPageBy(delta) {
		fromPatientIndex += delta;
		refreshPreview();
	}

	var fromPatientIndex = 0;
	var patientPageSize = 15;
	
	function refreshPreview() {
		var div = document.getElementById('cohort_builder_preview');
		showLayer('cohort_builder_preview_loading_message');
		hideLayer('cohort_builder_preview_numbers');
		hideLayer('cohort_builder_preview_patients');
		var method = DWRUtil.getValue('cohort_builder_preview_method');
		if (method == 'last')
			DWRCohortBuilderService.getLastResult(displayPreview);
		else if (method == 'and')
			DWRCohortBuilderService.getResultCombineWithAnd(displayPreview);
		else if (method == 'or')
			DWRCohortBuilderService.getResultCombineWithOr(displayPreview);
		else // should be an integer: a zero-based index into the search history
			DWRCohortBuilderService.getResultForSearch(method, displayPreview);
	}
	
	var currentPatientSet = null;
	var goesUntilLast = false;

	function displayPreview(ps) {
		currentPatientSet = ps;
		var ids = ps.patientIds;
		var n = ids.length;
		if (fromPatientIndex >= n)
			fromPatientIndex = n - patientPageSize;
		if (fromPatientIndex < 0)
			fromPatientIndex = 0;
		var toPatientIndex = fromPatientIndex + patientPageSize - 1;
		var patientIds = "";
		for (var i = fromPatientIndex; i <= toPatientIndex; ++i) {
			if (i == n) break;
			if (i > fromPatientIndex)
				patientIds += ",";
			patientIds += ids[i];
		}
		goesUntilLast = (toPatientIndex + 1) >= n;
		$('previewFromIndex').innerHTML = fromPatientIndex + 1;
		$('previewToIndex').innerHTML = toPatientIndex > n ? n : (toPatientIndex + 1);
		$('previewTotalNumber').innerHTML = n;
		hideLayer('cohort_builder_preview_patients');
		var str = '<i>' + n + ' <spring:message code="CohortBuilder.numResults"/></i>';
		DWRPatientSetService.getPatients(patientIds, function(list) {
				var str = '';
				if (fromPatientIndex > 0)
					str += '&nbsp;&nbsp;...<br/>';
				for (var j = 0; j < list.length; ++j) {
					var pli = list[j];
					str += "&nbsp;&nbsp;" + (fromPatientIndex + j + 1) + ". ";
					str += '<a href="patientDashboard.form?patientId=' + pli.patientId + '">';
					str += pli.givenName + " " + pli.familyName + " (" + pli.age + " year old " + (pli.gender == "M" ? "Male" : "Female") + ")";
					str += "</a><br/>";
				}
				if (!goesUntilLast)
					str += '&nbsp;&nbsp;...<br/>';
				var div = document.getElementById('cohort_builder_preview_patients');
				$('cohort_builder_preview_patients').innerHTML = str;
				hideLayer('cohort_builder_preview_loading_message');
				showLayer('cohort_builder_preview_numbers');
				showLayer('cohort_builder_preview_patients');
			});
	}
</script>

<h2><spring:message code="CohortBuilder.title"/></h2>	

<div id="cohort_builder_add_filter" style="padding: 4px">
	<b><spring:message code="general.search"/></b>

	<span style="padding: 3px 0px; margin: 0px 3px; background-color: #ffffaa; border: 1px black solid">
		<a href="javascript:handleSavedFilterMenuButton()"><spring:message code="CohortBuilder.savedFilterMenu"/></a>
	</span>
	<div id="saved_filters" style="position: absolute; z-index: 1; border: 1px black solid; background-color: yellow; display: none"></div>

	<c:if test="${fn:length(model.shortcuts) > 0}">
		<c:forEach var="shortcut" items="${model.shortcuts}" varStatus="status">
			<span style="padding: 3px 0px; margin: 0px 3px; background-color: #ffffaa; border: 1px black solid">
				<c:if test="${shortcut.concrete}">
					<a href="cohortBuilder.form?method=addFilter&filter_id=${shortcut.patientFilter.reportObjectId}"><spring:message code="${shortcut.label}"/></a>
				</c:if>
				<c:if test="${!shortcut.concrete}">
					<form id="shortcut${shortcut.label}" method="post" action="cohortBuilder.form" style="display: inline">
						<c:if test="${!shortcut.hasPromptArgs}">
							<a href="javascript:document.getElementById('shortcut${shortcut.label}').submit()">
						</c:if>
						<spring:message code="${shortcut.label}"/>
						<c:if test="${!shortcut.hasPromptArgs}">
							</a>
						</c:if>
						<input type="hidden" name="method" value="addDynamicFilter"/>
						<input type="hidden" name="filterClass" value="${shortcut.className}"/>
						<input type="hidden" name="vars" value="${shortcut.vars}"/>
						<c:forEach var="arg" items="${shortcut.args}">
							<c:if test="${empty arg.argClass}">
								<spring:message code="${arg.argName}"/>
							</c:if>
							<c:if test="${arg.argClass != null}">
								<c:choose>
									<c:when test="${not empty arg.argValue}">
										<input type="hidden" name="${arg.argName}" value="${arg.argValue}"/>
									</c:when>
									<c:otherwise>
										<spring:message code="${shortcut.label}.${arg.argName}"/>
										<openmrs:fieldGen type="${arg.argClass.name}" formFieldName="${arg.argName}" val="" parameters="optionHeader=[blank]|fieldLength=10" />
									</c:otherwise>
								</c:choose>
							</c:if>
						</c:forEach>
						<c:if test="${shortcut.hasPromptArgs}">
							<input type="submit" value="Go"/>
						</c:if>
					</form>
				</c:if>
			</span>
		</c:forEach>
	</c:if>
	
	<br/>
	
	<div id="cohortSearchTabs">
		<ul>
			<li>&nbsp;</li>
			<li><a id="searchTab_concept" href="#" onClick="changeSearchTab(this)"><spring:message code="CohortBuilder.searchTab.concept"/></a></li>
			<li><a id="searchTab_encounter" href="#" onClick="changeSearchTab(this)"><spring:message code="CohortBuilder.searchTab.encounter"/></a></li>
			<li><a id="searchTab_program" href="#" onClick="changeSearchTab(this)"><spring:message code="CohortBuilder.searchTab.program"/></a></li>
			<li><a id="searchTab_location" href="#" onClick="changeSearchTab(this)"><spring:message code="CohortBuilder.searchTab.location"/></a></li>
			<li><a id="searchTab_composition" href="#" onClick="changeSearchTab(this)"><spring:message code="CohortBuilder.searchTab.composition"/></a></li>
		</ul>
	</div>
	
	<div id="cohortSearchTabContent" style="border: 1px black solid; border-top: none; padding: 4px 5px 2px 10px;">
	
		<div id="searchTab_concept_content" style="display: none">
			<div dojoType="ConceptSearch" widgetId="concept_to_filter_search" conceptId="" searchLabel='<spring:message code="CohortBuilder.addConceptFilter"/>' showVerboseListing="true" includeVoided="false"></div>
			<div id="concept_filter_box" style="display: none; border-top: 1px #aaaaaa solid"></div>
		</div>
		
		<div id="searchTab_encounter_content" style="display: none">
			<spring:message code="CohortBuilder.addEncounterFilter"/>
			<ul><li>
			<form method="post" action="cohortBuilder.form">
				<input type="hidden" name="method" value="addDynamicFilter"/>
				<input type="hidden" name="filterClass" value="org.openmrs.reporting.EncounterPatientFilter" />
				<input type="hidden" name="vars" value="encounterType#org.openmrs.EncounterType,location#org.openmrs.Location,atLeastCount#java.lang.Integer,atMostCount#java.lang.Integer,withinLastMonths#java.lang.Integer,withinLastDays#java.lang.Integer,sinceDate#java.util.Date,untilDate#java.util.Date" />
				Patients having encounters
				<br/><span style="margin-left: 40px">
						(optional) of type
							<select name="encounterType">
								<option value=""><spring:message code="general.allOptions"/></option>
								<c:forEach var="encType" items="${model.encounterTypes}">
									<option value="${encType.encounterTypeId}">${encType.name}</option>
								</c:forEach>
							</select>
					</span>
				<br/><span style="margin-left: 40px">
						(optional) at location
							<select name="location">
								<option value=""><spring:message code="general.allOptions"/></option>
								<c:forEach var="location" items="${model.locations}">
									<option value="${location.locationId}">${location.name}</option>
								</c:forEach>
							</select>
					</span>
				<br/><span style="margin-left: 40px">
					(optional)
						at least this many <input type="text" size="3" name="atLeastCount" />
						and up to this many <input type="text" size="3" name="atMostCount" />
					</span>
				<br/><span style="margin-left: 40px">
					(optional)
						within the last <input type="text" size="3" name="withinLastMonths" />months
						and <input type="text" size="3" name="withinLastDays" />days
					</span>
				<br/><span style="margin-left: 40px">
					(optional)
						since <input type="text" size="10" name="sinceDate" onClick="showCalendar(this)" />
						until <input type="text" size="10" name="untilDate" onClick="showCalendar(this)" />
					</span>
				<br/>
				<input type="submit" value="<spring:message code="general.search" />"/>
				<input type="button" value="<spring:message code="general.cancel" />" onClick="hideLayer('encounter_filter_box')"/>
			</form>
			</li></ul>
		</div>
	
		<div id="searchTab_program_content" style="display: none">
			<spring:message code="CohortBuilder.addProgramFilter"/>
			<ul><li>
			<form method="post" action="cohortBuilder.form">
				<input type="hidden" name="method" value="addDynamicFilter"/>
				<input type="hidden" name="filterClass" value="org.openmrs.reporting.ProgramStatePatientFilter" />
				<input type="hidden" name="vars" value="program#org.openmrs.Program,state#org.openmrs.ProgramWorkflowState,withinLastMonths#java.lang.Integer,withinLastDays#java.lang.Integer,sinceDate#java.util.Date,untilDate#java.util.Date" />
	
				Program:
				<select name="program" id="program" onChange="refreshWorkflowOptions()">
					<option value=""></option>
					<c:forEach var="program" items="${model.programs}">
						<option value="${program.programId}">${program.concept.name.name}</option>
					</c:forEach>
				</select>
				<br/>
	
				Workflow: <select name="workflow" id="workflow" onChange="refreshStateOptions()"></select>
				State: <select name="state" id="state"></select>			
				
				<br/><span style="margin-left: 40px">
					(optional)
						on or after:<input type="text" size="10" name="sinceDate" onClick="showCalendar(this)" />
					</span>
				<br/><span style="margin-left: 40px">
					(optional)
						on or before:<input type="text" size="10" name="untilDate" onClick="showCalendar(this)" />
					</span>
				
				<br/>
				<input type="submit" value="<spring:message code="general.search" />"/>
				<input type="button" value="<spring:message code="general.cancel" />" onClick="hideLayer('program_filter_box')"/>
			</form>
			</li></ul>
		</div>
		
		<div id="searchTab_location_content" style="display: none">
			<spring:message code="CohortBuilder.addLocationFilter"/>
			<ul><li>
			<form method="post" action="cohortBuilder.form">
				<input type="hidden" name="method" value="addDynamicFilter"/>
				<input type="hidden" name="filterClass" value="org.openmrs.reporting.EncounterPatientFilter" />
				<input type="hidden" name="vars" value="location#org.openmrs.Location,calculationMethod#org.openmrs.api.PatientSetService$PatientLocationMethod" />
				Patients belonging to
				<select name="location">
					<option value=""><spring:message code="general.none" /></option>
					<c:forEach var="location" items="${model.locations}">
						<option value="${location.locationId}">${location.name}</option>
					</c:forEach>
				</select>
				according to method
				<select name="calculationMethod">
					<option value="PATIENT_HEALTH_CENTER">Assigned Health Center</option>
					<option value="ANY_ENCOUNTER">Any Encounter</option>
					<option value="LATEST_ENCOUNTER">Most Recent Encounter</option>
					<option value="EARLIEST_ENCOUNTER">Earliest Encounter</option>
				</select>			
				<br/>
				<input type="submit" value="<spring:message code="general.search" />"/>
				<input type="button" value="<spring:message code="general.cancel" />" onClick="hideLayer('program_filter_box')"/>
			</form>
			</li></ul>
		</div>
		
		<div id="searchTab_composition_content" style="display: none">
			<form method="post" action="cohortBuilder.form">
				<input type="hidden" name="method" value="addFilter"/>
				<spring:message code="CohortBuilder.addCompositionFilter"/>
				<input type="text" name="composition" id="composition" size="40"/>
				<input type="submit" value="<spring:message code="general.add"/>"/>
				<br/>
				<i><small>
					<spring:message code="CohortBuilder.compositionHelp"/>
				</small></i>
			</form>
		</div>
	</div>
	
</div>

<div id="cohort_builder_search_history" style="padding: 4px; border: 1px black solid; background-color: #e8e8e8">

	<div id="saveBox" style="position: absolute; z-index: 1; border: 1px black solid; background-color: #ffe0e0; display: none">
		<form method="post" action="cohortBuilder.form">
			<input type="hidden" name="method" value="saveHistory"/>
			<table>
				<tr>
					<th colspan="2"><spring:message code="CohortBuilder.searchHistory.save"/></th>
				</tr>
				<tr>
					<td><spring:message code="general.name"/></td>
					<td><input type="text" name="name"/></td>
				</tr>
				<tr>
					<td><spring:message code="general.description"/></td>
					<td><input type="text" name="description" size="60"/></td>
				</tr>
				<!--
				<tr>
					<td><spring:message code="CohortBuilder.privateOrShared"/></td>
					<td><spring:message code="general.notYetImplemented"/></td>
				</tr>
				<tr>
					<td><spring:message code="CohortBuilder.keepUntil"/></td>
					<td>
						<select>
							<option value=""><spring:message code="CohortBuilder.keepUntil.forever"/></option>
							<option value=""><spring:message code="general.nWeeks" arguments="4"/> (<spring:message code="general.notYetImplemented"/>)</option>
							<option value=""><spring:message code="general.nWeeks" arguments="2"/> (<spring:message code="general.notYetImplemented"/>)</option>
							<option value=""><spring:message code="general.nWeeks" arguments="1"/> (<spring:message code="general.notYetImplemented"/>)</option>
						</select>
					</td>
				</tr>
				-->
			</table>
			<div align="center">
				<input style="margin: 0em 1em" type="submit" value="<spring:message code="general.save"/>"/>
				<input style="margin: 0em 1em" type="button" value="<spring:message code="general.cancel"/>" onClick="toggleLayer('saveBox')"/>
			</div>
		</form>
	</div>

	<div id="loadBox" style="position: absolute; margin: 1em; padding: 1em; z-index: 1; border: 1px black solid; background-color: #ffe0e0; display: none"></div>

	<h3>
		<spring:message code="CohortBuilder.searchHistory"/>
		<c:if test="${model.searchHistory.size > 0}">
			<img src="${pageContext.request.contextPath}/images/save.gif" title="<spring:message code="general.save"/>" onClick="toggleLayer('saveBox'); hideLayer('loadBox')"/>
		</c:if>
		<img src="${pageContext.request.contextPath}/images/open.gif" title="<spring:message code="general.load"/>" onClick="handleLoadButton()"/>
		<form method="post" action="cohortBuilder.form" style="display: inline">
			<input type="hidden" name="method" value="clearHistory"/>
			<input type="image" title="<spring:message code="CohortBuilder.searchHistory.clear"/>" src="${pageContext.request.contextPath}/images/delete.gif"/>
		</form>
	</h3>

	<div id="saveFilterBox" style="padding: 1em; position: absolute; z-index: 1; border: 1px black solid; background-color: #ffe0e0; display: none">
		<b><u><spring:message code="CohortBuilder.cohortDefinition.save"/></u></b>
		<br/><br/>
		<spring:message code="general.saving" arguments="<span id=\"saveFilterTitle\"></span>"/>
		<br/><br/>
		<spring:message code="general.name"/>: <input type="text" id="saveFilterName"/> <br/>
		<spring:message code="general.description"/>: <input type="text" id="saveFilterDescription" size="60"/> <br/><br/>
		<input type="hidden" id="saveFilterIndex"/>
		<div align="center">
			<input type="button" id="saveFilterSaveButton" value="<spring:message code="general.save"/>" onClick="handleSaveFilter()"/>
			<input type="button" id="saveFilterCancelButton" value="<spring:message code="general.cancel"/>" onClick="toggleLayer('saveFilterBox')"/>
		</div>
	</div>	
			
	<c:if test="${model.searchHistory.size == 0}">
		<div><spring:message code="CohortBuilder.searchHistory.none"/></div>
	</c:if>
	<c:if test="${model.searchHistory.size > SHOW_LAST_N}">
		<div id="fullSearchHistory" style="display: none">
			<div style="text-align: center">
				<a href="javascript:hideLayer('fullSearchHistory'); showLayer('showFullSearchHistoryButton')"><spring:message code="CohortBuilder.searchHistory.showRecent"/></a>
			</div>
	</c:if>
	<c:forEach var="item" items="${model.searchHistory.items}" varStatus="iter">
		<c:if test="${model.searchHistory.size > SHOW_LAST_N && iter.index == (model.searchHistory.size - SHOW_LAST_N)}">
			</div>
			<div id="showFullSearchHistoryButton" style="text-align: center">
				<a href="javascript:showLayer('fullSearchHistory'); hideLayer('showFullSearchHistoryButton')"><spring:message code="CohortBuilder.searchHistory.showFull"/></a>
			</div>
		</c:if>
		
		<table style="margin: 1px 4px; width: 100%; border: 1px black solid; background-color: #e0ffe0">
			<tr>
				<td width="25">
					<c:set var="temp" value="${iter.index}"/>
					<c:if test="${iter.count == model.searchHistory.size}"> <%-- TODO: is there a single method in varstatus for this? --%>
						<c:set var="temp" value="last"/>
					</c:if>
					<a href="#" onClick="DWRUtil.setValue('cohort_builder_preview_method', '${temp}'); refreshPreview();">
						${iter.count}.
					</a>
				</td>
				<td>
					${item.filter.name}
					<c:if test="${not empty item.filter.description}">
						<small>${item.filter.description}</small>
					</c:if>
				</td>
				<td align="right">
					<span id="results_for_filter_${iter.count}">
						<c:if test="${item.cachedResult != null}">
							${item.cachedResult.size}
						</c:if>
						<c:if test="${item.cachedResult == null}">
							?
						</c:if>
					</span>
					<spring:message code="CohortBuilder.numResults"/>
					<c:if test="${item.cachedResult != null}">
						<small>(cached)</small>
					</c:if>
					<img src="${pageContext.request.contextPath}/images/save.gif" onClick="showSaveFilterDialog(${iter.index}, '${item.filter.name}')"/>
					<a href="cohortBuilder.form?method=removeFilter&index=${iter.index}"><img src="${pageContext.request.contextPath}/images/delete.gif"/></a>
				</td>
				<c:if test="${item.cachedResult == null}">
					<script type="text/javascript">
						DWRCohortBuilderService.getResultCountForSearch(${iter.index},
							function(count) {
								var temp = document.getElementById('results_for_filter_${iter.count}');
								temp.innerHTML = count;
							});
					</script>
				</c:if>
			</tr>
		</table>
	</c:forEach>
</div>

<div id="cohort_builder_preview" style="padding: 4px<c:if test="${model.searchHistory.size == 0}">; display: none"</c:if>">

	<div id="cohort_builder_button_panel" style="padding: 1px 4px; margin: 4px 0px">
		<table width="100%">
			<tr>
				<td>
					<spring:message code="CohortBuilder.displayMethod"/>
					<select id="cohort_builder_preview_method" onChange="refreshPreview()">
						<option value="last"><spring:message code="CohortBuilder.displayMethod.last"/></option>
						<option value="and"><spring:message code="CohortBuilder.displayMethod.and"/></option>
						<option value="or"><spring:message code="CohortBuilder.displayMethod.or"/></option>
						<c:set var="temp" value="${model.searchHistory.size - 2}"/>
						<c:if test="${temp < 0}">
							<c:set var="temp" value="0"/>
						</c:if>
						<c:forEach varStatus="index" items="${model.searchHistory.items}" end="${temp}">
							<option value="${index.index}">${index.count}</option>
						</c:forEach>
					</select>
				</td>
			</tr>
		</table>
	</div>

	<div id="cohort_builder_preview_numbers" style="display: none">
		<b><u>
		<a href="javascript:previewPageTo(0)">|&lt;-</a>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<a href="javascript:previewPageBy(-patientPageSize)">&lt;-</a>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<spring:message code="general.displayingXtoYofZ" arguments="<span id=\"previewFromIndex\">#</span>,<span id=\"previewToIndex\">#</span>,<span id=\"previewTotalNumber\">#</span>"/>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<a href="javascript:previewPageBy(patientPageSize)">-&gt;</a>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<a href="javascript:previewPageTo(-1)">-&gt;|</a>
		</u></b>
	</div>
	
	<div id="cohort_builder_preview_loading_message">
		<spring:message code="general.loading"/>
	</div>
	<div id="cohort_builder_preview_patients" style="display: none; margin-bottom: 15px"></div>

	<div id="cohort_builder_actions" style="position: relative; border: 1px black solid">
		<div id="saveCohortDiv" style="position: absolute; margin: 1em; padding: 1em; bottom: 0px; border: 2px black solid; background-color: #e0e0e0; display: none">
			<b><u>Save Cohort (i.e. list of patient ids)</u></b>
			<br/><br/>
			Name: <input type="text" id="saveCohortName"/> <br/>
			Description: <input type="text" id="saveCohortDescription"/> <br/>
			<br/>
			<i>Note: this actually works, but it doesn't give you any indication. And you can't use a cohort anywhere yet.</i> <br/>
			<br/>
			<div align="center">
				<input type="button" value="<spring:message code="general.save"/>" onClick="handleSaveCohort()" />
				<input type="button" value="<spring:message code="general.cancel"/>" onClick="toggleLayer('saveCohortDiv')" />
			</div>
		</div>

		<c:if test="${fn:length(model.links) > 0}">
			<div id="_linkMenu" style="	border: 1px solid black; background-color: #f0f0a0; position: absolute; bottom: 0px; padding-right: 1.2em; z-index: 1; display: none">
				<br />
				&nbsp;&nbsp;&nbsp;<span style="width: 200px; text-align: right;"><a href="#" onClick="javascript:hideLayer('_linkMenu');" >[Close]</a></span>
				<ul>
					<c:forEach var="item" items="${model.links}" varStatus="loopStatus">
						<li>
							<form method="post" action="${item.url}" id="link_${loopStatus.index}_form" style="display: inline" <c:if test="${model.linkTarget != null}">target="${model.linkTarget}"</c:if>>
								<input type="hidden" name="patientIds" id="link_${loopStatus.index}_ptIds" value=""/>
								<c:forEach var="arg" items="${item.arguments}">
									<input type="hidden" name="${arg.name}" value="${arg.value}"/>
								</c:forEach>
								<input type="hidden" name="fDate" id="link_${loopStatus.index}_fDate" value="" />
								<input type="hidden" name="tDate" id="link_${loopStatus.index}_tDate" value="" />
								<a href="javascript:linkSubmitHelper('link_${loopStatus.index}')">
									<spring:message code="${item.label}"/>
								</a>
							</form>
						</li>
					</c:forEach>
				</ul>
				&nbsp;&nbsp;<spring:message code="general.dateConstraints" /> (<spring:message code="general.optional" />):<br />
				<table style="padding-left: 15px;">
					<tr>
						<td><spring:message code="general.fromDate" />:</td>
						<td><openmrs:fieldGen type="java.util.Date" formFieldName="nrFromDate" val="" /></td>
					</tr>
					<tr>
						<td><spring:message code="general.toDate" />:</td>
						<td><openmrs:fieldGen type="java.util.Date" formFieldName="nrToDate" val="" /></td>
					</tr>
				</table>
				<br />
			</div>
		</c:if>

		<b><spring:message code="CohortBuilder.actionsMenu"/></b>

		<img title="<spring:message code="general.save" />" src="${pageContext.request.contextPath}/images/save.gif" onClick="toggleLayer('saveCohortDiv')"/>

		<c:if test="${fn:length(model.links) > 0}">
			<a href="javascript:toggleLayer('_linkMenu')" style="border: 1px black solid"><spring:message code="Analysis.linkButton"/></a>
		</c:if>

	</div>

</div>

<script type="text/javascript">
	changeSearchTab('searchTab_concept');
	refreshPreview();
</script>

<%@ include file="/WEB-INF/template/footer.jsp" %> 