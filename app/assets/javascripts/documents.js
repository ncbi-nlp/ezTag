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
  $("#defaultTypeSelector select").change(function(e) {
    var selected = $("#defaultTypeSelector select option:selected");
    console.log(selected);
    localStorage && localStorage.setItem('defaultType_' + options.collectionId, selected.text());
    if (selected.hasClass("new")) {
      console.log("has class");
      self.addNewEntity();
    }
  });
  console.log('defaultType_' + options.collectionId);
  var defaultType = localStorage && localStorage.getItem('defaultType_' + options.collectionId);
  if (defaultType) {
    var types = $.map($("#defaultTypeSelector select option"), function(item) {return $(item).text();});
    if (types.includes(defaultType)) {
      $("#defaultTypeSelector select").val(defaultType);  
    } else {
      localStorage && localStorage.removeItem('defaultType_' + options.collectionId);
    }
  }
  this.restoreScrollTop();
  $(window).scroll(_.debounce(this.storeScrollTop.bind(this), 100));
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
  console.log(name);
  var same = _.filter($("#annotationModal select option"), function(e) {
    return $(e).text() == name
  });
  console.log(same);

  if (same.length === 0) {
    var $option = $("<option></option>").text(name).attr("value", name);
    $s.prepend($option);
    $s.val(name);
    $s.find("option.nothing").remove();

    $.ajax({
      url: $s.data('url'),
      method: "POST",
      data: {entity_type: {name: name}}, 
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      success: function(data) {
        console.log(data);

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
        console.log(range);
        if (range.startContainer != range.endContainer) {
          clearSelection();
          return;
        }
        var el = $(range.startContainer.parentElement || range.startContainer.parentNode)
        if (el.hasClass("annotation")) {
          clearSelection();
          return;
        }
        if (!el.hasClass("phrase")) {
          clearSelection();
          return;
        }
        node = range.startContainer;

        var length = range.endOffset - range.startOffset;
        if (length > 0) {
          // recommends = getRecommendText(range);
          var elemOffset = parseInt($(range.startContainer.parentElement).data('offset'), 10);
          var offset = elemOffset + range.startOffset;
          var type = $("#defaultTypeSelector option:selected").text();
          var text = $(range.startContainer).text().substr(range.startOffset, length);
          if (!type) {
            self.addNewEntity();
            type = $("#defaultTypeSelector option:selected").text();
            if (!type) {
              toastr.error("Cannot save an annotation without assigning an entity type");
              return;
            }
          }
          $.ajax({
            url: $("#annotationModal form").attr("action") + ".json",
            method: "POST",
            data: {text: text, offset: offset, type: type}, 
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
            success: function(data) {
              $("#main-document").load($("#main-document").data("url"), function() {
                self.bindAnnotationSpan();
                // toastr.success("Successfully added.");              
              });
              self.annotations = data.annotations;
              self.entity_types = data.entity_types;
              $("#annotationList").prepend(self.templates.view1({
                id: data.annotation.id, offset: data.annotation.offset, 
                text: data.annotation.text, passage: data.annotation.passage,
                size: 1, type: data.annotation.type, concept: data.annotation.concept
              }));
              $("#annotationList tr:first-child").addClass("new");
              self.bindAnnotationTr();
              $(".annotation-tr:first-child .concept").click();
            },
            error: function(xhr, status, err) {
              toastr.error(err);              
            },
            complete: function() {
              $("#annotationModal .dimmer").removeClass("active");
            }
          });

          // self.showLocationSelector(recommends, range);
        } else {
          console.log("????", length);
        }
      }
    });
  }

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
            size: text.length, type: last.type, concept: last.concept
          }));
        } else {
          html.push(self.templates.view2({
            id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage
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
        size: text.length, type: last.type, concept: last.concept
      }));
    } else {
      html.push(self.templates.view2({
        id: text[j].id, offset: text[j].offset, text: text[j].text, passage: text[j].passage
      }));
    }
  }
  $("#annotationList").html(html.join("\n"));
  self.bindAnnotationTr();
};

BioC.prototype.bindAnnotationTr = function() {
  var self = this;
  $(".annotation-tr").unbind("mouseover mouseout")
    .mouseover(function(e) {
      var $e = $(e.currentTarget);
      var cls = ".AL_" + $e.data('id') + '_' + $e.data('offset');
      $(cls).css("border-bottom", "4px solid #f44");
    })
    .mouseout(function(e) {
      var $e = $(e.currentTarget);
      var cls = ".AL_" + $e.data('id') + '_' + $e.data('offset');
      $(cls).css("border-bottom", "0");
    });
  $(".annotation-tr .td-annotation-text").unbind('click')
    .click(function(e) {
      var $e = $(e.currentTarget).parent();
      if ($e.data('passage')) {
        self.scrollToPasssage($e.data('passage'));
      }
    })

  $(".annotation-tr .icon.search").unbind("click").click(function(e) {
    var $e = $(e.currentTarget);
    self.clickAnnotation($e.closest("tr"));
  });
  if (!self.busy) {
    $(".annotation-tr .concept").unbind("click").click(self.clickConcept.bind(self));
    $(".annotation-tr .type-text").unbind("click").click(self.clickEntityType.bind(self));
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
  var oldValue = $tr.find(".concept-text").text().trim();
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
  var concept = $tr.find(".concept-text").text().trim();
  var isMention = (!concept);
  if (oldValue !== newValue) {
    $.ajax({
      url: self.endpoints.annotations + "/" + $tr.data('id') + ".json",
      method: "PATCH",
      data: {mode: !isMention, concept: concept, type: newValue}, 
      success: function(data) {
        $("#main-document").load($("#main-document").data("url"), function() {
          self.bindAnnotationSpan();
          // toastr.success("Successfully added.");              
        });
        $tr.removeClass("new");
        $td.data('value', newValue);
        self.restoreTR();
        toastr.success("Successfully updated.");              
        self.annotations = data.annotations;
        self.entity_types = data.entity_types;
      },
      error: function(xhr, status, err) {
        toastr.error(err);              
      },
      complete: function() {
      }
    });
  } else {
    $tr.removeClass("new");
    self.restoreTR();
  }
};

BioC.prototype.updateConcept = function($tr) {
  console.log("UPDATE concept")
  var self = this;
  var type = $tr.find(".type").text().trim();
  var oldValue = $tr.find(".concept-text").text().trim();
  var newValue = $tr.find(".concept-edit input").val().trim();
  var isMention = (!oldValue);
  if (oldValue !== newValue) {
    $.ajax({
      url: self.endpoints.annotations + "/" + $tr.data('id') + ".json",
      method: "PATCH",
      data: {mode: !isMention, concept: newValue, type: type}, 
      success: function(data) {
        $tr.removeClass("new");
        self.restoreTR();
        $tr.find(".concept-text").text(newValue);
        $tr.find(".concept-edit input").val(newValue);
        toastr.success("Successfully updated.");              
        self.annotations = data.annotations;
        self.entity_types = data.entity_types;
      },
      error: function(xhr, status, err) {
        toastr.error(err);              
      },
      complete: function() {
      }
    });
  } else {
    $tr.removeClass("new");
    self.restoreTR();
  }
};

BioC.prototype.clickAnnotation = function(e) {
  var self = this;
  var $e = $(e);
  console.log("Clicked", $e);
  var id = $e.data('id').toString();
  if (!id) {
    console.log("Sorry, No id");
    return;
  }
  if ($e.data('passage')) {
    this.scrollToPasssage($e.data('passage'));
  }
  var all_a = _.filter(this.annotations, {id: id});
  var a = all_a[0];
  var offsets = _.map(all_a, function(a) {return a.offset});
  if (!a) {
    console.log("Sorry, There is no A");
    return;
  }
  var old_type = a.type;
  var old_concept = a.concept;
  $("#annotationModal .hide-for-add").show();
  $("#annotationModal .show-for-add").hide();
  $("#annotationModal .for-annotate-all").hide();
  $(".btn-update-text").text("Update");
  $("#annotationModal .header").html(a.text);
  $("#annotationModal input[name='text']").val(a.text);
  $("#annotationModal input[name='offset']").val(offsets.join(","));
  $("#annotationModal select[name='type']").dropdown("set selected", a.type);
  $("#annotationModal input[name='concept']").val(a.concept);
  if (a.concept.match(/^MESH:/i)) {
    var parts = a.concept.split(":");
    $("#showMeshBtn").attr('href', 'https://meshb.nlm.nih.gov/record/ui?ui=' + parts[1]);
    $("#showMeshBtn").show();
  }
  else if (a.concept.match(/^[CDQ][0-9]+$/i)) {
    $("#showMeshBtn").attr('href', 'https://meshb.nlm.nih.gov/record/ui?ui=' + a.concept);
    $("#showMeshBtn").show();
  } else {
    $("#showMeshBtn").attr('href', '#').hide();
  }
  $("#annotationModal input[name='mode']").prop("checked", $e.hasClass("concept"));
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
            $("#main-document").load($("#main-document").data("url"), function() {
              self.bindAnnotationSpan();
              toastr.success("Successfully deleted.");              
              $("#annotationModal .dimmer").removeClass("active");
            });
            self.annotations = data.annotations;
            self.entity_types = data.entity_types;
            self.renderAnnotationTable();
            $("#annotationModal").modal("hide");
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
      onVisible: function() {
        setTimeout(function() {
          $("#annotationModal input[name='concept']").focus();
        }, 10);
      },
      onApprove: function() {
        $("#annotationModal input[name='concept']").val($("#annotationModal input[name='concept']").val().trim());
        var new_type = $("#annotationModal select[name='type']").val();
        var new_concept = $("#annotationModal input[name='concept']").val();
        var mode = $("#annotationModal input[name='mode']").val();
        var needAnnotateAll = ($(".btn-update-text").text() != "Update");
        if (old_concept == new_concept && old_type == new_type && !needAnnotateAll) {
          return;
        }
        $("#annotationModal .dimmer").addClass("active");
        $.ajax({
          url: $("#annotationModal form").attr("action") + "/" + encodeURIComponent(a.id) + ".json",
          method: "PATCH",
          data: $("#annotationModal form").serialize(), 
          success: function(data) {
            console.log("SUCCESS", old_type, new_type)
            if (old_type != new_type || needAnnotateAll) {
              $("#main-document").load($("#main-document").data("url"), function() {
                self.bindAnnotationSpan();
                toastr.success("Successfully updated.");              
              });
            } else {
              toastr.success("Successfully updated.");              
            }
            self.annotations = data.annotations;
            self.entity_types = data.entity_types;
            self.renderAnnotationTable();
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
