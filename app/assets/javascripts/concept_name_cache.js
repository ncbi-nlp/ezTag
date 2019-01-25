var ConceptNameCache = function() {
  this.init();
};

ConceptNameCache.prototype.init = function() {
  this.listForFetch = [];
};

ConceptNameCache.prototype.escape = function(id) {
  return id.replace(/[:\s,;\|]/, "-");
};

ConceptNameCache.prototype.get = function(id, cb) {
  var self = this;
  var e = self.extractID(id);
  console.log("FOUND ID:", e);
  if (!e.type) {
    if (cb) {
      cb(id);
    }
    return id;
  }
  var cbNames = [];
  var cb2 = cb && function(error, name) {
    cbNames.push(name);
    if (cbNames.length >= e.id.length) {
      var finalName = self.get(id);
      if (cb) {
        cb(null, finalName);
      }
    }
  };

  var names = _.map(e.id, function(id) {
    return self._get(e.type + ":" + id, cb2);
  });
  return names.join(', ');
};


ConceptNameCache.prototype._get = function(id, cb) {
  var self = this;
  var name = localStorage && localStorage.getItem(id);
  if (name) {
    if (cb) {
      cb(null, name);
    }
    console.log('Get <' + id + " : " + name +"> from cache");
    return name;
  } else {
    if (cb) {
      self.fetch(id, cb);
    } else {
      if (this.listForFetch.indexOf(id) === -1) {
        console.log('Cache miss: put list << ' + id);
        this.listForFetch.push(id);
      }      
    }
    return id;
  }
};

ConceptNameCache.prototype.postFound = function(id, name) {
  console.log('change title [' + '.concept-text.for-' + this.escape(id) + "]" + name);
  $('.concept-text.for-' + this.escape(id)).prop('title', name); 
};

ConceptNameCache.prototype.fetchAll = function() {
  var self = this;
  console.log("Fetch all for " + self.listForFetch.join(","));
  _.each(self.listForFetch, function(id) {
    var name = localStorage && localStorage.getItem(id);
    if (!name) {
      self.fetch(id);
    } else {
      self.postFound(id, name);
    }
  });
  self.listForFetch = [];
};

ConceptNameCache.prototype.getFetchTypeAndURL = function(id) {
  var parts = id.split(":");
  if (id.match(/^MESH:/i)) {
    return {
      url: 'https://id.nlm.nih.gov/mesh/' + parts[1] + '.json',
      type: "MESH",
      dataType: 'json',
      parseName: function(data) {
        return data && data['@graph'] && 
              data['@graph'][0] && data['@graph'][0].label &&
              data['@graph'][0].label['@value'];
      }
    };
  } else if (id.match(/^GENE:/i)) {
    return {
      url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gene&id='+ parts[1] + '&format=json',
      type: 'GENE',
      dataType: 'json',
      parseName: function(data) {
        return data && data.result && data.result[parts[1]] && data.result[parts[1]].name;
      }
    }
  }
  return {};
};

ConceptNameCache.prototype.__stripIdType = function(type, str) {
  var r = new RegExp('^' + type + ':', 'i');
  var m = str.replace(r, '');
  return m;
};

ConceptNameCache.prototype.extractID = function(str) {
  var self = this;
  var ret = {
    type: null,
    id: []
  };
  var remain = str;
  if (str.match(/^MESH:/i)) {
    ret.type = "MESH";
  } else if (str.match(/^GENE:/i)) {
    ret.type = "GENE";
  }
  ret.id = _.map(_.compact(str.split(/[,\s;\|]/)), function(id) {
    console.log("ID=", id);
    id = self.__stripIdType(ret.type, id);
    var m = id.match(/^([^-]+)/);
    return m && m[1];
  });
  ret.id = _.compact(ret.id);
  return ret;
};

ConceptNameCache.prototype.fetch = function(id, cb) {
  var self = this;
  var ret = self.getFetchTypeAndURL(id);
  if (ret && ret.url) {
    $.ajax({
      url: ret.url,
      method: 'GET',
      dataType: ret.dataType,
      success: function(data) {
        var name = ret.parseName(data);
        if (name) {
          console.log('Fetch success <' + id + " : " + name +">");
          localStorage && localStorage.setItem(id, name);
          self.postFound(id, name);
          if (cb) {
            return cb(null, name);
          }      
        } else {
          self.postFound(id, id);
          if (cb) {
            return cb(null, id);
          }
        }
      }, 
      error: function(xhr, status, err) {
        console.error(err);              
      }
    })
  }
};
