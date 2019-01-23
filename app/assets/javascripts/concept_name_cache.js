var ConceptNameCache = function() {
  this.init();
};

ConceptNameCache.prototype.init = function() {
  this.listForFetch = [];
};

ConceptNameCache.prototype.escape = function(id) {
  return id.replace(":", "-");
};

ConceptNameCache.prototype.get = function(id, cb) {
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
  console.log('change title [' + '.context-text.for-' + this.escape(id) + "]" + name);
  $('.context-text.for-' + this.escape(id)).prop('title', name); 
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
      type: "mesh",
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
      type: 'gene',
      dataType: 'json',
      parseName: function(data) {
        return data && data.result && data.result[parts[1]] && data.result[parts[1]].name;
      }
    }
  }
  return {};
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
