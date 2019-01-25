var BioC = function(id, options) {
  this.initPaneWidthHeight();
  var self = this;
  options = _.extend({
    isReadOnly: false,
    root: '/'
  }, options);
  if (options.root.slice(-1) != "/") {
    options.root = options.root + "/";
  }
  this.collectionId = options.collectionId;
  this.endpoints = options.endpoints;
  this.annotations = options.annotations;
  this.templates = options.templates;
  this.id = id;
  this.url = options.root + "documents/" + id;
  this.busy = options.busy;
  this.conceptNameCache = options.conceptNameCache;
  this.renderAnnotationTable();
  this.initModal();
  $(".refresh-annotation-table").click(function(e) {
    e.stopPropagation();
    self.renderAnnotationTable();
    return false;
  });

  $(window).on('resize', function() {
    this.initPaneWidthHeight();
  }.bind(this));
  this.initOutlineScroll();

  self.bindAnnotationSpan(); 
  if (options.busy) {
    $(".action-button").prop('disabled', true).addClass("disabled");
  }
  $(".add-new-entity").click(self.addNewEntity.bind(self));
  $("#defaultTypeSelector select").val($("#defaultTypeSelector option:first").val());
  $("#defaultTypeSelector select").change(function(e) {
    var selected = $("#defaultTypeSelector select option:selected");
    console.log(selected);
    if (selected.hasClass('type')) {
      localStorage && localStorage.setItem('defaultType_' + options.collectionId, selected.text());
    }
    if (selected.hasClass("new")) {
      self.addNewEntity();
    }
  });
  console.log('defaultType_' + options.collectionId);
  var defaultType = localStorage && localStorage.getItem('defaultType_' + options.collectionId);
  if (defaultType) {
    var types = $.map($("#defaultTypeSelector select option.type"), function(item) {return $(item).text();});
    if (types.includes(defaultType)) {
      $("#defaultTypeSelector select").val(defaultType);  
    } else {
      localStorage && localStorage.removeItem('defaultType_' + options.collectionId);
      $("#defaultTypeSelector select").val($("#defaultTypeSelector option:first").val());
    }
  }
  this.restoreScrollTop();
  $(window).scroll(_.debounce(this.storeScrollTop.bind(this), 100));
  $("#annotationTableUpButton").click(function() {
    $('.right-side.pane').animate({scrollTop: 0},
       500, 
       "easeOutQuint"
    );
  });
  $("#annotationTableDownButton").click(function() {
    $('.right-side.pane').animate({scrollTop: $('#annotationTable').height()},
       500, 
       "easeOutQuint"
    );
  });
  $("#documentSpinner").removeClass("active");
  $(".concept-id-head").click(function(e) {
    var $e = $(e.currentTarget);
    $e.closest('table').toggleClass('show-concept-name');
  })
};

BioC.prototype.addNewEntity = function() {
  var $s = $("#defaultTypeSelector select");
  var name = prompt("Enter a new entity type (only alphanumeric characters and '_' are allowed)");
  if (!name) {
    $s[0].selectedIndex =0;
    return;
  }
  name = name.trim().replace(/ /g,"_").replace(/[^\w_\s]/gi, '');
  if (!name) {
    toastr.error("Invalid entity type")
    $s[0].selectedIndex =0;
    return;
  }
  var same = _.filter($("#annotationModal select option"), function(e) {
    return $(e).text() == name
  });

  if (same.length === 0) {
    var $option = $("<option class='type'></option>").text(name).attr("value", name);
    $s.prepend($option);
    $s.val(name);
    $s.find("option.nothing").remove();
    $s.change();

    $.ajax({
      url: $s.data('url'),
      method: "POST",
      data: {entity_type: {name: name}}, 
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      success: function(data) {
        $option = $("<option></option>").text(name).attr("value", name)
        $("#annotationModal select[name='type']").append($option);
        setTimeout(function(){
          $("#annotationModal select[name='type']").dropdown("set selected", name);
        }, 100);
      }, 
      error: function(err) {
        console.error(err);
        toastr.error(err.responseText || err); 
        $s[0].selectedIndex =0;
      }
    });
    
  } else {
    $s.val($(same[0]).val());
  }
};

BioC.prototype.bindAnnotationSpan = function() {
  var self = this;
  $("span.annotation").click(function(e) {
    self.clickAnnotation(e.currentTarget);
  });

  if (!this.busy) {
    $(".passage").mouseup(function (e) {   
      var selection = getSelected();
      if (selection && selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);

        var result = self.findAnnotationRange(range);
        if (result.error) {
          toastr.error("You cannot work with multiple paragraphs. Please select a span in a paragraph.");
          clearSelection();
          return;
        }

        var length = range.endOffset - range.startOffset;

        if (result.annotations.length == 0 && length > 0) {
          if (result.text.length != length) {
            console.log("Something wrong " + length + " !=" + result.text.length);
            clearSelection();
            return;
          }
          // recommends = getRecommendText(range);
          var elemOffset = parseInt($(range.startContainer.parentElement).data('offset'), 10);
          var offset = elemOffset + range.startOffset;
          var text = $(range.startContainer).text().substr(range.startOffset, length).trim();
          if (result.text.length != length) {
            console.log("Something wrong in text: " + text + " !=" + result.text);
            clearSelection();
            return;
          }
          self.addNewAnnotation(text, offset);
          
          // self.showLocationSelector(recommends, range);
        } else if (result.annotations.length > 0) {
          
          if (result.annotations.length == 1 && result.text.length == 0) {

          } else if (result.annotations.length > 0) {
            self.showAnnotationListModal(result.annotations, result.offset, result.text);
          }
          clearSelection();
        } else {
          console.log("????", length);
          clearSelection();
        }
      }
    });
  }
};

BioC.prototype.addNewAnnotation = function(text, offset, type) {
  var self = this;
  if (!type) {
    type = $("#defaultTypeSelector option:selected").text();
  }
  if (!type) {
    self.addNewEntity();
    type = $("#defaultTypeSelector option:selected").text();
    if (!type) {
      toastr.error("Cannot save an annotation without assigning an entity type");
      return;
    }
  }
  $(".document-loader").addClass("active");
  $.ajax({
    url: $("#annotationModal form").attr("action") + ".json",
    method: "POST",
    data: {text: text, offset: offset, type: type}, 
    beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
    success: function(data) {
      self.reloadMainDocument();
      self.annotations = data.annotations;
      self.entity_types = data.entity_types;
      if (data.annotation) {
        $("#annotationList").prepend(self.templates.view1({
          id: data.annotation.id, offset: data.annotation.offset, 
          text: data.annotation.text, passage: data.annotation.passage,
          size: 1, type: data.annotation.type, concept: data.annotation.concept
        }));     
        $("#annotationList tr:first-child").addClass("new");
        self.bindAnnotationTr();
        $("#annotationList .annotation-tr:first-child .concept").click();
      } else {
        toastr.error("Unable to create an annotation. Maybe texts are located in sentences."); 
      }
    },
    error: function(xhr, status, err) {
      $(".document-loader").removeClass("active");
      toastr.error(err);              
    },
    complete: function() {
    }
  });
};

BioC.prototype.findAnnotationRange = function(range) {
  var annotations = [];
  var ids;
  var wholeText = "";
  var $start = $(range.startContainer.parentElement);
  var $end = $(range.endContainer.parentElement);
  var startPassage = range.startContainer.parentElement.parentElement;
  var endPassage = range.endContainer.parentElement.parentElement;
  
  if (startPassage != endPassage) {
    return {error: 'Different Passage!'};
  }
  
  var elemOffset = parseInt($(range.startContainer.parentElement).data('offset'), 10);
  var offset = elemOffset + range.startOffset;

  var $p = $start;
  var startOffset, endOffset;
  var text;
  while($p.data('offset') <= $end.data('offset')) {
    text = $p.text();
    startOffset = 0;
    endOffset = text.length;
    if ($p.data('offset') == $start.data('offset')) {
      startOffset = range.startOffset;
    }
    if ($p.data('offset') == $end.data('offset')) {
      endOffset = range.endOffset;
    }
    text = text.substr(startOffset, endOffset - startOffset);
    wholeText += text;

    if ($p.hasClass('annotation')) {
      ids = $p.data('ids');
      if (ids.split) {
        ids = ids.split(" ");
      } else {
        ids = [ids];
      }
      _.each(ids, function(id) {
        annotations.push("" + id);
      });
    }
    $p = $p.next();
  }
  annotations = _.uniq(annotations).sort();
  return {
    offset: offset,
    text: wholeText.trim(),
    annotations: annotations,
  };
};

BioC.prototype.updateAnnotationListModal = function(annotationIds) {
  var self = this;

  if (!annotationIds) {
    var ids = $("#annotationListModal .content").data('ids');
    if (ids && ids.split) {
      annotationIds = ids.split(' ');
    }
  } else {
    $("#annotationListModal .content").data('ids', annotationIds.join(" "));
  }

  if (!annotationIds) {
    return;
  }

  var annotations = _.filter(self.annotations, function(a) {
    return annotationIds.includes(a.id); 
  });
  annotations.sort(function(a, b) {
    return a.offset - b.offset;
  });
  $("#annotationListModal .annotationListCount").text(annotations.length);

  var bodyHtml = _.map(annotations, function(a) {
    var item = Object.assign({}, a);
    item.conceptName = self.conceptNameCache.get(a.concept);
    if (a.updated_at) {
      item.updated_at = moment(a.updated_at).local().format("LLL");
      item.yymmdd = moment(a.updated_at).local().format('YYYY-MM-DD');
    }
    item.iconClass = (a.note) ?'comment': 'search';
    return self.templates.annotationList(item);
  });
  $("#annotationListModal .annotationListTableBody").html(bodyHtml.join("\n"));
  $("#annotationListModal .annotation-tr .concept").unbind("click").click(self.clickConcept.bind(self));
  $("#annotationListModal .annotation-tr .type-text").unbind("click").click(self.clickEntityType.bind(self));

  $("#annotationListModal .annotation-tr .icon.show-popup").unbind("click").click(function(e) {
    var $e = $(e.currentTarget);
    self.clickAnnotation($e.closest("tr"), {force: true});
  });
};

BioC.prototype.showAnnotationListModal = function(annotationIds, offset, text) {
  var self = this;
  var titleHelp = "Offset [" + offset + ":" + (offset + text.length) + "] (length: " + text.length + ")";
  var titleText = "<span class='annotation-text-span need-popup-title' data-position='bottom left' data-content='" + titleHelp + "'>" + text + "</span>";
  if (text.length > 0) {
    $("#annotationListModal .header").html(titleText);
  } else {
    $("#annotationListModal .header").html("");
  }  
  $("#annotationListModal input[type='checkbox']").prop('checked', false);
  $("#annotationListModal thead input[type='checkbox']").change(function(e) {
    var val = $(e.currentTarget).is(':checked');
    $("#annotationListModal input[type='checkbox']").prop('checked', val);
  });
  $("#annotationListModal .ui.button.create-new").toggleClass('disabled', (text.length <= 0));
  self.updateAnnotationListModal(annotationIds);
  $("#annotationListModal").modal({
    allowMultiple: true,
    onApprove: function($e) {
      if ($e.hasClass('create-new')) {
        self.addNewAnnotation(text, offset);      
      }
    },
    onDeny: function($e) {
      if ($e.hasClass('delete-checked')) {
        var $checked = $("#annotationListModal .annotationListTableBody input[type='checkbox']:checked");
        if ($checked.length == 0) {
          alert('Please select annotations which you want delete.');
          return false;
        }
        if (confirm("Are you sure to delete " + $checked.length + " annotation(s)?")) {
          var offsets = _.map($checked, function(item) {
            var $tr = $(item).closest('tr');
            return {id: $tr.data('id'), offset: $tr.data('offset')};
          });
          self.deleteCheckedAnnotation(offsets)
        }
        return false;
      }
    }
  }).modal('show');
  $('.need-popup-title').popup();
//   $("#annotationListModal thead input[type='checkbox']").blur();
//   $("#annotationListModal input[type='text']:first").focus();
//   setTimeout(function() {
//     console.log("blue-------------");
//     $("#annotationListModal thead input[type='checkbox']").blur();
//     $("#annotationListModal input[type='text']:first").focus();
//   }, 400);
};

BioC.prototype.deleteCheckedAnnotation = function(offsets) {
  var self = this;
  var id = offsets[0].id;
  console.log(offsets);
  $.ajax({
    url: $("#annotationModal form").attr("action") + "/" + encodeURIComponent(id) + ".json",
    method: "DELETE",
    data: {
      deleteMode: 'batch', 
      offsets: offsets
    }, 
    success: function(data) {
      self.reloadMainDocument(function() {
        toastr.success("Successfully deleted.");              
      });
      self.annotations = data.annotations;
      self.entity_types = data.entity_types;
      self.renderAnnotationTable();
      self.refreshAnnotationListModal();
    },
    error: function(xhr, status, err) {
      toastr.error(err);              
    },
  });
};

// BioC.prototype.showLocationSelector = function(list, range) {
//   var minPos = 999999;
//   var maxPos = -99999;
//   var node = range.startContainer;
//   var elemOffset = parseInt($(range.startContainer.parentElement).data('offset'), 10);
//   var nodeText = $(node).text();
//   var self = this;
//   $("#rangeSelectModal table.recommends tbody").empty();

//   _.each(list, function(obj) {
//     if (obj.length <= 0) return;
//     if (obj.offset < minPos) {
//       minPos = obj.offset;
//     }
//     if (obj.offset + obj.length > maxPos) {
//       maxPos = obj.offset + obj.length;
//     }
//     var trHtml = "<tr data-offset='" + obj.offset + "' data-length='" + obj.length + "'>" +
//                       "<td>'" + obj.text + "'</td><td>" + obj.offset + "</td>" + "<td>" + obj.length + "</td>" +
//                       "<td><button class='ui button mini'>Change Range</button></td></tr>";
//     $("#rangeSelectModal table.recommends tbody").prepend(trHtml);
//   });

//   var trCnt = _.size($("#rangeSelectModal table.recommends tbody tr"));
//   if (trCnt == 0 && list[0].length === 0) {
//     minPos = list[0].offset;
//     maxPos = list[0].offset + 1;
//   }

//   $("#rangeSelectModal table.recommends tbody tr button").click(function(e) {
//     var tr = $(e.target).parents("tr");
//     var selection = [tr.data("offset"), tr.data("offset") + tr.data("length") - 1];
//     changeSliderSelection(selection);
//   });

//   minPos = minPos - 30;
//   maxPos = maxPos + 30;

//   if (minPos < elemOffset) {
//     minPos = elemOffset;
//   }

//   if (maxPos > nodeText.length + elemOffset) {
//     maxPos = nodeText.length + elemOffset;
//   }

//   var text = nodeText.substr(minPos - elemOffset, maxPos - minPos + 1);
//   var offset = minPos;
//   var startPos = range.startOffset + elemOffset;
//   var endPos = startPos + range.toString().length - 1;
//   if (endPos < startPos) {
//     endPos = startPos;
//   }
//   console.log(range);
//   console.log("MIN:MAX" + offset + ":" + (offset+text.length - 1));
//   var selection = [startPos, endPos];
//   // $("#rangeSelectModal .slider-div .start").text(offset);
//   // $("#rangeSelectModal .slider-div .end").text(offset + text.length - 1);
//   $("#rangeSelectModal .text").data("offset", offset);
//   $("#rangeSelectModal .text").text(text);
//   $("#rangeSelectModal .text-real").text(text);
//   console.log(selection);

//   if (self.slider) {
//     self.slider.noUiSlider.destroy();
//   }

//   self.slider = document.getElementById('slider');

//   noUiSlider.create(self.slider, {
//     start: selection,
//     connect: true,
//     range: {
//       min: offset,
//       max: offset + text.length - 1
//     },
//     pips: {
//       mode: 'range',
//       density: 5
//     }
//   });
//   self.slider.noUiSlider.on('update', function ( values, handle ) {
//     var newSelection = _.map(values, function(v) {return parseInt(v);});
//     if (newSelection[0] != selection[0] || newSelection[1] != selection[1]) {
//       markSelection(newSelection);
//     }
//   });
//   if (range.toString().length === 0 && trCnt > 0) {
//     $("#rangeSelectModal table.recommends tbody tr button:first").click();
//   } else {
//     changeSliderSelection(selection);
//   }

//   clearSelection();
//   $("#rangeSelectModal").modal({
//     onApprove: function() {
//       $("#annotationModal .header").html($("#rangeSelectModal .text span").text());
//       $("#annotationModal input[name='text']").val($("#rangeSelectModal .text span").text());
//       $("#annotationModal input[name='offset']").val($("#rangeSelectModal #loc_offset").val());
//       $("#annotationModal select[name='type']").dropdown("set selected", $("#annotationModal select[name='type'] option:first-child").text());
//       $("#annotationModal input[name='concept']").val("");
//       $("#annotationModal .hide-for-add").hide();
//       $("#annotationModal .show-for-add").show();
//       $("#annotationModal .dimmer").removeClass("active");
//       $("#annotationModal").modal({
//         onVisible: function() {
//           setTimeout(function() {
//             $("#annotationModal input[name='concept']").focus();
//           }, 10);
//         },
//         onApprove: function() {
//           $("#annotationModal input[name='concept']").val($("#annotationModal input[name='concept']").val().trim());
//           $("#annotationModal .dimmer").addClass("active");
//           $.ajax({
//             url: $("#annotationModal form").attr("action") + ".json",
//             method: "POST",
//             data: $("#annotationModal form").serialize(), 
//             success: function(data) {
//               $("#main-document").load($("#main-document").data("url"), function() {
//                 self.bindAnnotationSpan();
//                 toastr.success("Successfully added.");              
//               });
//               self.annotations = data.annotations;
//               self.entity_types = data.entity_types;
//               self.renderAnnotationTable();
//             },
//             error: function(xhr, status, err) {
//               toastr.error(err);              
//             },
//             complete: function() {
//               $("#annotationModal .dimmer").removeClass("active");
//             }
//           });
//         }
//       }).modal("show");
//     }
//   }).modal("show");
// };

// function changeSliderSelection(selection) {
//   var s = selection[0];
//   var e = selection[1];

//   console.log("selection1 : " + [s, e]);
//   this.slider.noUiSlider.set([s, e]);
//   console.log("selection2 : " + [s, e]);
//   markSelection([s, e]);
// }

// function markSelection(selection) {
//   var min = $("#rangeSelectModal .text").data("offset");
//   var text = $("#rangeSelectModal .text").text();
//   text = text.replace(/&nbsp;/g , " ");
//   var maxLength = text.length;
//   var offset = selection[0];
//   var length = selection[1] - selection[0] + 1;

//   if (offset < min) {
//     offset = min;
//   }

//   if (offset + length > min + maxLength) {
//     if (offset >= min + maxLength) {
//       offset = min + maxLength - 1;
//     }
//     if (offset + length > min + maxLength) {
//       length = min + maxLength - offset;
//     }
//   }
//   console.log("selection in markSelection : " + selection);
//   console.log(offset + ":" + length);
//   var part1 = text.substr(0, offset - min);
//   var part2 = text.substr(offset - min, length);
//   var part3 = text.substr(offset - min + length, maxLength - (offset - min + length));
//   console.log("orig:'" + text+"'");
//   console.log("1:'" + part1+"'");
//   console.log("2:'" + part2+"'");
//   console.log("3:'" + part3+"'");
//   text = part1 + "<span>" + part2 + "</span>" + part3;
//   text = text.replace(/ /g , "&nbsp;");
//   $("#rangeSelectModal .text").html(text);
//   $("#rangeSelectModal #loc_offset").val(offset);
//   $("#rangeSelectModal #loc_length").val(length);
//   return [offset, offset + length - 1];
// }

BioC.prototype.renderAnnotationTable = function() {
  var self = this;
  this.annotations.sort(function(a, b) {
    if (a.type > b.type) {
      return 1;
    } 
    if (a.type < b.type) {
      return -1;
    }
    if (a.concept > b.concept) {
      return 1;
    } 
    if (a.concept < b.concept) {
      return -1;
    } 
    return a.offset - b.offset;
    // return a.text.localeCompare(b.text);
  });
  self.conceptNameCache.init();
  $("#annotationHead").html(self.templates.head);
  var html, text;
  html = [];
  text = [];
  var last = {};
  var concept, type;
  for(var i = 0; i < this.annotations.length; i++) {
    var a = self.annotations[i];
    if (last.type !== a.type || (last.concept !== a.concept || a.concept.trim().length === 0)) {
      for(var j = 0; j < text.length; j++) {
        if (j == 0) {
          html.push(self.templates.view1({
            id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage,
            size: text.length, type: last.type, 
            concept: last.concept, conceptName: self.conceptNameCache.get(last.concept),
            conceptId: self.conceptNameCache.escape(last.concept),
            iconClass: (text[j].note ?'comment': 'search')
          }));
        } else {
          html.push(self.templates.view2({
            id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage, iconClass: (text[j].note ?'comment': 'search')
          }));
        }
      }
      last.type = a.type;
      last.concept = a.concept;
      last.text = a.text;
      text = [a];
    } else {
      text.push(a);
      if (last.text !== a.text) {
        last.text = a.text;
      }
    }
  }
  for(var j = 0; j < text.length; j++) {
    if (j == 0) {
      html.push(self.templates.view1({
        id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage,
        size: text.length, type: last.type, 
        concept: last.concept, conceptName: self.conceptNameCache.get(last.concept),
        conceptId: self.conceptNameCache.escape(last.concept),
        iconClass: (text[j].note ?'comment': 'search')
      }));
    } else {
      html.push(self.templates.view2({
        id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage, iconClass: (text[j].note ?'comment': 'search')
      }));
    }
  }
  $("#annotationList").html(html.join("\n"));
  self.bindAnnotationTr();
  self.conceptNameCache.fetchAll();
  // $(".need-popup").popup();
};

BioC.prototype.bindAnnotationTr = function() {
  var self = this;
  $("#annotationTable .annotation-tr").unbind("mouseover mouseout")
    .mouseover(function(e) {
      var $e = $(e.currentTarget);
      var cls = ".AL_" + $e.data('id') + '_' + $e.data('offset');
      $(cls).addClass("focused-now");
      // $(cls).css("border-bottom", "4px solid #f44");
    })
    .mouseout(function(e) {
      var $e = $(e.currentTarget);
      var cls = ".AL_" + $e.data('id') + '_' + $e.data('offset');
      $(cls).removeClass("focused-now");
      // $(cls).css("border-bottom", "0");
    });
  $("#annotationTable .annotation-tr .td-annotation-text").unbind('click')
    .click(function(e) {
      var $e = $(e.currentTarget).parent();
      if ($e.data('passage')) {
        self.scrollToPasssage($e.data('passage'));
      }
    })

  $("#annotationTable .annotation-tr .icon.show-popup").unbind("click").click(function(e) {
    var $e = $(e.currentTarget);
    self.clickAnnotation($e.closest("tr"));
  });
  if (!self.busy) {
    $("#annotationTable .annotation-tr .concept").unbind("click").click(self.clickConcept.bind(self));
    $("#annotationTable .annotation-tr .type-text").unbind("click").click(self.clickEntityType.bind(self));
  }
  $("#annotationTable").removeClass("selectable");
};

BioC.prototype.clickEntityType = function(e) {
  console.log("click concept");
  this.restoreTR();
  var self = this;
  var $e = $(e.currentTarget);
  var $tr = $e.closest("tr");
  var $td = $tr.find("td.type");
  $td.addClass("editing");
  var oldValue = $td.text().trim();
  $td.data('value', oldValue);
  $td.find(".type-edit").html($("<select/>").html($("#annotationModal select[name='type']").html()));
  $td.find("select").val(oldValue).focus();
  $td.find("select").unbind('change').change(function(e) {
    self.updateEntityType($tr);
  });
  $td.find("select").unbind('blur').blur(function() {
    self.updateEntityType($tr);
  });
};

BioC.prototype.restoreTR = function(e) {
  _.each($("td.type.editing"), function(cell) {
    var $e = $(cell);
    $e.removeClass("editing")
    $e.find(".type-edit").empty();
    $e.find(".type-text").html($e.data("value"));
  });
  $(".annotation-tr").removeClass("editable");
};

BioC.prototype.clickConcept = function(e) {
  console.log("click concept");
  var self = this;
  e.stopPropagation();
  var $e = $(e.currentTarget);
  var $tr = $e.closest("tr");
  var oldValue = $tr.find(".concept-text.for-id").text().trim();
  this.restoreTR();
  $tr.addClass("editable");  
  $tr.find(".concept-edit input").val(oldValue).focus();
  $tr.find(".concept-edit input").unbind('change').change(function() {
    self.updateConcept($tr);
  });
  $tr.find(".concept-edit input").unbind('blur').blur(function() {
    self.updateConcept($tr);
  });
};

BioC.prototype.updateEntityType = function($tr) {
  console.log("UPDATE entity_type")
  var self = this;
  var $td = $tr.find("td.type");
  var newValue = $td.find("select").val();
  var oldValue = $td.data("value");
  var concept = $tr.find(".concept-text.for-id").text().trim();
  var isMention = ($tr.data('mode') == 'mention') || (!concept);
  if (oldValue !== newValue) {
    $tr.find('.type .dimmer').addClass('active');
    $.ajax({
      url: self.endpoints.annotations + "/" + $tr.data('id') + ".json",
      method: "PATCH",
      data: {mode: !isMention, concept: concept, type: newValue, no_update_note: true}, 
      success: function(data) {
        self.reloadMainDocument();
        $tr.removeClass("new");
        $td.data('value', newValue);
        self.restoreTR();
        toastr.success("Successfully updated.");              
        self.annotations = data.annotations;
        self.entity_types = data.entity_types;
        self.refreshAnnotationListModal();
      },
      error: function(xhr, status, err) {
        toastr.error(err);              
      },
      complete: function() {
        $tr.find('.type .dimmer').removeClass('active');
      }
    });
  } else {
    $tr.removeClass("new");
    self.restoreTR();
  }
};

BioC.prototype.refreshAnnotationListModal = function() {
  if ($("#annotationListModal").is(":visible")) {
    this.updateAnnotationListModal();
    this.renderAnnotationTable();
  }
};

BioC.prototype.updateConcept = function($tr) {
  console.log("UPDATE concept")
  var self = this;
  var type = $tr.find(".type").text().trim();
  var oldValue = $tr.find(".concept-text.for-id").text().trim();
  var newValue = $tr.find(".concept-edit input").val().trim();
  var isMention = ($tr.data('mode') == 'mention') || (!oldValue);
  if (oldValue !== newValue) {
    $tr.find('.concept .dimmer').addClass('active');
    $.ajax({
      url: self.endpoints.annotations + "/" + $tr.data('id') + ".json",
      method: "PATCH",
      data: {mode: !isMention, concept: newValue, type: type, no_update_note: true}, 
      success: function(data) {
        self.reloadMainDocument();
        $tr.removeClass("new");
        self.restoreTR();
        $tr.find(".concept-text.for-id").text(newValue)
            .removeClass('for-' + self.conceptNameCache.escape(oldValue))
            .addClass('for-' + self.conceptNameCache.escape(newValue));
        $tr.find(".concept-edit input").val(newValue);
        self.conceptNameCache.get(newValue, function(ret, name) {
          $tr.find(".concept-text").prop('title', name);
        });
        toastr.success("Successfully updated.");              
        self.annotations = data.annotations;
        self.entity_types = data.entity_types;
        self.refreshAnnotationListModal();
      },
      error: function(xhr, status, err) {
        toastr.error(err);              
      },
      complete: function() {
        $tr.find('.concept .dimmer').removeClass('active');
      }
    });
  } else {
    $tr.removeClass("new");
    self.restoreTR();
  }
};

BioC.prototype.showAnnotationModal = function(id) {
  var self = this;
  var all_a = _.filter(this.annotations, {id: id});
  var a = all_a[0];
  var offsets = _.map(all_a, function(a) {return a.offset});
  if (!a) {
    console.log("Sorry, There is no A");
    return;
  }
  var old_type = a.type;
  var old_concept = a.concept;
  var old_note = a.note;
  $("#annotationModal .hide-for-add").show();
  $("#annotationModal .show-for-add").hide();
  $("#annotationModal .for-annotate-all").hide();
  $(".btn-update-text").text("Update");
  $("#annotationModal .header").html(a.text);
  $("#annotationModal input[name='text']").val(a.text);
  $("#annotationModal input[name='offset']").val(offsets.join(","));
  $("#annotationModal select[name='type']").dropdown("set selected", a.type);
  $("#annotationModal input[name='concept']").val(a.concept);
  $("#annotationModal input[name='note']").val(a.note);

  self.conceptNameCache.get(a.concept, function(ret, name) {
    if (name) {
      $("#annotationModal .concept-name").text(name);
    } else {
      $("#annotationModal .concept-name").text("");
    }
  });
  var links = self.conceptNameCache.extractID(a.concept);

  $("#showMoreBtn").data("type", links.type)
  $("#showMoreBtn").data("id", links.id.join(","));
  if (links.type == "MESH") {
    $("#showMoreBtn").attr('href', 'https://meshb.nlm.nih.gov/record/ui?ui=' + links.id[0]);
    $("#showMoreBtn").show();
  }
  else if (links.type == "GENE") {
    $("#showMoreBtn").attr('href', 'https://www.ncbi.nlm.nih.gov/gene/' + links.id.join(","));
    $("#showMoreBtn").show();
  } else {
    $("#showMoreBtn").attr('href', '#').hide();
  }

  $("#annotationModal #showMoreBtn").unbind("click").click(function(e) {
    var $e = $(e.currentTarget);
    var type = $e.data("type");
    var ids = $e.data("id").split(",");
    if (type == "MESH" && ids.length > 1) {
      e.preventDefault();
      _.each(ids, function(id) {
        window.open('https://meshb.nlm.nih.gov/record/ui?ui=' + id);      
      })
      return false;
    }
    return true;
  });
  // $("#annotationModal input[name='mode']").prop("checked", $e.hasClass("concept"));
  $("#annotationModal input[name='annotate_all']").prop("checked", false);
  $("#annotationModal .dimmer").removeClass("active");
  if (this.busy) {
    $(".action-button").hide();
  }
  $("#annotationModal .ui.checkbox.case-sensitive").checkbox("uncheck");
  $("#annotationModal .ui.checkbox.whole-word").checkbox("check");
  $("#annotationModal .ui.checkbox.annotate-all").checkbox({
    onChecked: function() {
      $("#annotationModal .for-annotate-all").show();
      $(".btn-update-text").text("Update & Annotate All")
    },
    onUnchecked: function() {
      $("#annotationModal .for-annotate-all").hide();
      $(".btn-update-text").text("Update");
    }
  }).checkbox('uncheck');
  $("#annotationModal input[name='concept']").keyup(function() {
    var text = $(this).val().trim();
    if (text) {
      $("#annotationModal .ui.checkbox.annotate-all").checkbox('set enabled');
    } else {
      $("#annotationModal .ui.checkbox.annotate-all").checkbox('set disabled');
    }
  }).keyup();
  
  var update_msgs = [];
  if (a.annotator || a.updated_at) {
    update_msgs.push("Last updated");
    if (a.annotator) {
      update_msgs.push("by <i class='annotator'>" + a.annotator + "</i>");
    }
    if (a.updated_at) {
      // update_msgs.push("at <i class='updated_at'>" + a.updated_at + "</i>");
      update_msgs.push("at <i class='updated_at'>" + moment(a.updated_at).local().format('LLL') + "</i>");
    }
  }
  $("#annotationModal .update_log").html(update_msgs.join(" "));
  $("#annotationModal .delete-annotation")
    .dropdown({
      action: 'hide', 
      onChange: function(value) {
        $("#annotationModal .dimmer").addClass("active");
        $("#annotationModal input[name='deleteMode']").val(value);
        $.ajax({
          url: $("#annotationModal form").attr("action") + "/" + encodeURIComponent(a.id) + ".json",
          method: "DELETE",
          data: $("#annotationModal form").serialize(), 
          success: function(data) {
            self.reloadMainDocument(function() {
              toastr.success("Successfully deleted.");              
              $("#annotationModal .dimmer").removeClass("active");
            });
            self.annotations = data.annotations;
            self.entity_types = data.entity_types;
            self.renderAnnotationTable();
            $("#annotationModal").modal("hide");
            self.refreshAnnotationListModal();
          },
          error: function(xhr, status, err) {
            toastr.error(err);              
            $("#annotationModal .dimmer").removeClass("active");
          },
        });
      }
    });
  $("#annotationModal .delete-annotation .item").removeClass("active selected");
  $("#annotationModal")
    .modal({
      allowMultiple: true,
      onVisible: function() {
        setTimeout(function() {
          $("#annotationModal input[name='concept']").focus();
        }, 10);
      },
      onApprove: function() {
        $("#annotationModal input[name='concept']").val($("#annotationModal input[name='concept']").val().trim());
        var new_type = $("#annotationModal select[name='type']").val();
        var new_concept = $("#annotationModal input[name='concept']").val();
        var new_note = $("#annotationModal input[name='note']").val();
        var mode = $("#annotationModal input[name='mode']").val();
        var needAnnotateAll = ($(".btn-update-text").text() != "Update");
        if (old_concept == new_concept && old_note == new_note && old_type == new_type && !needAnnotateAll) {
          return;
        }
        if (old_concept != new_concept) {
          self.conceptNameCache.get(new_concept, function() {}); // prefetch
        }
        $("#annotationModal .dimmer").addClass("active");
        $.ajax({
          url: $("#annotationModal form").attr("action") + "/" + encodeURIComponent(a.id) + ".json",
          method: "PATCH",
          data: $("#annotationModal form").serialize(), 
          success: function(data) {
            console.log("SUCCESS", old_type, new_type)
            if (old_type != new_type || needAnnotateAll) {
              self.reloadMainDocument(function() {
                toastr.success("Successfully updated.");   
              });
            } else {
              toastr.success("Successfully updated.");              
            }
            self.annotations = data.annotations;
            self.entity_types = data.entity_types;
            self.renderAnnotationTable();
            self.refreshAnnotationListModal();
          },
          error: function(xhr, status, err) {
            toastr.error(err);              
          },
          complete: function() {
            $("#annotationModal dimmer").removeClass("active");
          }
        });
      }
    })
    .modal("show");
};
BioC.prototype.reloadMainDocument = function(done) {
  var self = this;
  $(".document-loader").addClass("active");
  $("#main-document").load($("#main-document").data("url"), function() {
    self.bindAnnotationSpan();
    $(".document-loader").removeClass("active");
    if (done) {
      done();
    }           
  });
}
BioC.prototype.clickAnnotation = function(e, option) {
  var self = this;
  var $e = $(e);
  var force = option && option.force;
  if ($("#annotationListModal").is(":visible") && !force) {
    return;
  }
  console.log("Clicked", $e);
  var id = $e.data('id').toString();
  if (!id) {
    console.log("Sorry, No id");
    return;
  }
  if ($e.data('passage')) {
    self.scrollToPasssage($e.data('passage'));
  }
  // var all_a = _.filter(self.annotations, {id: id});
  // var a = all_a[0];
  // var offsets = _.map(all_a, function(a) {return a.offset});
  
  self.showAnnotationModal(id);
};

function uniquePush(ret, item) {
  for(var i in ret) {
    var obj = ret[i];
    if (obj.offset == item.offset && obj.length == item.length) {
      return;
    }
  }

  ret.push(item);
}

// function getRecommendText(range) {
//   var ret = [];

//   var node = range.startContainer;
//   var parent = $(range.startContainer.parentElement);
//   var elemOffset = parseInt(parent.data('offset'), 10);
//   var startPos = range.startOffset;
//   var offset = elemOffset + startPos ;
//   var text = range.toString();
//   var length = text.length;
//   var ch;
//   var nodeText = $(node).text();
//   var recommendText, rec_offset, rec_length;
//   var found = false;

//   uniquePush(ret, {text: text, offset: offset, length: length});

//   if ((range.startOffset > 0 && nodeText.charAt(startPos - 1) != ' ') ||
//       (range.startOffset + length < nodeText.length && nodeText.charAt(startPos + length ) != ' '))
//   {
//     rec_offset = startPos;
//     rec_length = length;

//     while (rec_offset > 0 && nodeText.charAt(rec_offset - 1) != ' ') {
//       rec_offset--;
//       rec_length++;
//     }

//     while (rec_offset + rec_length < nodeText.length && nodeText.charAt(rec_offset + rec_length) != ' ') {
//       rec_length++;
//     }

//     recommendText = nodeText.substr(rec_offset, rec_length);
//     rec_offset += elemOffset;
//     uniquePush(ret, {text: recommendText, offset: rec_offset, length: rec_length});


//     found = false;

//     // Trimming start whitespace
//     while (rec_length > 0 && ".,()".indexOf(recommendText.charAt(0)) >= 0) {
//       rec_offset++;
//       rec_length--;
//       found = true;

//       recommendText = recommendText.substr(1);
//     }

//     // Trimming end whitespace
//     while (rec_length > 0 && ".,()".indexOf(recommendText.charAt(rec_length - 1)) >= 0) {
//       rec_length--;
//       found = true;

//       recommendText = recommendText.substr(0, rec_length);
//     }

//     if (found) {
//       uniquePush(ret, {text: recommendText, offset: rec_offset, length: rec_length});
//     }
//   }

//   rec_offset = offset;
//   rec_length = length;
//   recommendText = text;

//   found = false;
//   // Trimming start whitespace
//   while (rec_length > 0 && (recommendText.charAt(0)) == ' ') {
//     rec_offset++;
//     rec_length--;
//     recommendText = recommendText.substr(1);
//     found = true;
//   }

//   // Trimming end whitespace
//   while (rec_length > 0 && (recommendText.charAt(rec_length - 1)) == ' ') {
//     rec_length--;
//     recommendText = recommendText.substr(0, rec_length);
//     found = true;
//   }

//   if (found) {
//     uniquePush(ret, {text: recommendText, offset: rec_offset, length: rec_length});
//   }

//   found = false;

//   // Trimming start whitespace
//   while (rec_length > 0 && ".,()".indexOf(recommendText.charAt(0)) >= 0) {
//     rec_offset++;
//     rec_length--;
//     found = true;

//     recommendText = recommendText.substr(1);
//   }

//   // Trimming end whitespace
//   while (rec_length > 0 && ".,()".indexOf(recommendText.charAt(rec_length - 1)) >= 0) {
//     rec_length--;
//     found = true;

//     recommendText = recommendText.substr(0, rec_length);
//   }

//   if (found) {
//     uniquePush(ret, {text: recommendText, offset: rec_offset, length: rec_length});
//   }
//   return ret;
// }

function getSelected() {
  if(window.getSelection) { return window.getSelection(); }
  else if(document.getSelection) { return document.getSelection(); }
  else {
    var selection = document.selection && document.selection.createRange();
    if(selection.text) { return selection.text; }
    return false;
  }
  return false;
}

function clearSelection() {
  if (window.getSelection) {
    if (window.getSelection().empty) {  // Chrome
      window.getSelection().empty();
    } else if (window.getSelection().removeAllRanges) {  // Firefox
      window.getSelection().removeAllRanges();
    }
  } else if (document.selection) {  // IE?
    document.selection.empty();
  }
}

BioC.prototype.initPaneWidthHeight = function() {
  var width = parseInt($(".document").width(), 10);
  var leftWidth = ($(".document").hasClass("outline") ? 200 : 0);
  var rightWidth = (width > 991) ? 350 : 250;
  var mainWidth = width - (rightWidth + leftWidth);
  
  if (width > 2000) {
    mainWidth = 1300;
  } else if (width > 1600) {
    mainWidth = 1200 - leftWidth;
  } else if (width > 1400) {
    mainWidth = 1050 - leftWidth;
  }
  if (mainWidth >= 850) {
    rightWidth = width - (mainWidth + leftWidth);
  }
  if (mainWidth < 400) {
    mainWidth = mainWidth + leftWidth;
    leftWidth = 0;
  }

  $(".main.pane").css("margin-left", leftWidth + "px");    
  $(".left-side.pane").toggle(leftWidth > 0);  
  $(".main.pane").width(mainWidth + "px");
  $(".right.pane").css('left', (($(".main.pane").outerWidth() + leftWidth) + "px"))
                  .css('width', rightWidth + 'px').show();
};


BioC.prototype.initOutlineScroll = function() {
  var self = this;
  $('.outline-link').click(function(e) {
    e.preventDefault();
    self.scrollToPasssage($.attr(this, 'href'));
    return false;
  });
};

BioC.prototype.scrollToPasssage = function(passage) {
  $("html, body").animate({
      scrollTop: ($(passage).offset().top - 130) 
    }, 300);
};

BioC.prototype.storeScrollTop = function() {
  var pos = $("html, body").scrollTop();
  localStorage && localStorage.setItem('ScrollTop_' + this.id, pos);
  console.log("last pos: " + pos);
}

BioC.prototype.restoreScrollTop = function() {
  var pos = localStorage && localStorage.getItem('ScrollTop_' + this.id);
  if (pos && pos > 0) {
    if (confirm("Do you want to go to the last used location in the document?")) {
      $("html, body").animate({
          scrollTop: pos 
        }, 300);
    } else {
      localStorage && localStorage.removeItem('ScrollTop_' + this.id);
    }
  }
}

BioC.prototype.initModal = function() {
  $(".doc-info-btn").click(function() {
    $(".modal.doc-info").modal({
      blurring: true
    })
    .modal('show');
  });

  $(".infon-btn").click(function(e) {
    var id = $(e.currentTarget).data("id");
    e.preventDefault();
    $(".modal.infon-" + id).modal({
      blurring: true
    })
    .modal('show');
    return false;
  });
 
};
