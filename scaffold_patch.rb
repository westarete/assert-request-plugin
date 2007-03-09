# This script will patch the scaffold and scaffold_resource generators in 
# your latest rails installation so that they include the appropriate calls
# to assert_request. In the case of scaffold_resource, it will also modify
# the scaffolding's functional tests so that they work right away.
#
# To apply the patch on Mac or Linux, just run this script as the superuser:
#   sudo ruby scaffold_patch.rb
#
# This script probably won't work on Windows, since there's no patch command
# by default.

require 'rubygems'
rails = Gem.source_index.find_name("rails").sort_by {|spec| spec.version}.last
if rails.nil?
  raise "can't find the latest rails gem on this machine"
end
puts "patching #{rails.full_gem_path}"
Dir.chdir rails.full_gem_path
IO.popen("patch -p0", "w") { |cmd| cmd.write(DATA.read) }

__END__
Index: lib/rails_generator/generators/components/scaffold/templates/controller.rb
===================================================================
--- lib/rails_generator/generators/components/scaffold/templates/controller.rb	(revision 6337)
+++ lib/rails_generator/generators/components/scaffold/templates/controller.rb	(working copy)
@@ -16,18 +16,32 @@
          :redirect_to => { :action => :list<%= suffix %> }
 
   def list<%= suffix %>
+    assert_request do |r|
+      r.method :get
+    end
     @<%= singular_name %>_pages, @<%= plural_name %> = paginate :<%= plural_name %>, :per_page => 10
   end
 
   def show<%= suffix %>
+    assert_request do |r|
+      r.method :get
+      r.params.must_have :id
+    end
     @<%= singular_name %> = <%= model_name %>.find(params[:id])
   end
 
   def new<%= suffix %>
+    assert_request do |r|
+      r.method :get
+    end
     @<%= singular_name %> = <%= model_name %>.new
   end
 
   def create<%= suffix %>
+    assert_request do |r|
+      r.method :post
+      r.params.must_have <%= model_name %>
+    end
     @<%= singular_name %> = <%= model_name %>.new(params[:<%= singular_name %>])
     if @<%= singular_name %>.save
       flash[:notice] = '<%= model_name %> was successfully created.'
@@ -38,10 +52,18 @@
   end
 
   def edit<%= suffix %>
+    assert_request do |r|
+      r.method :get
+      r.params.must_have :id
+    end
     @<%= singular_name %> = <%= model_name %>.find(params[:id])
   end
 
   def update
+    assert_request do |r|
+      r.method :post
+      r.params.must_have :id, <%= model_name %>
+    end
     @<%= singular_name %> = <%= model_name %>.find(params[:id])
     if @<%= singular_name %>.update_attributes(params[:<%= singular_name %>])
       flash[:notice] = '<%= model_name %> was successfully updated.'
@@ -52,6 +74,10 @@
   end
 
   def destroy<%= suffix %>
+    assert_request do |r|
+      r.method :post
+      r.params.must_have :id
+    end
     <%= model_name %>.find(params[:id]).destroy
     redirect_to :action => 'list<%= suffix %>'
   end
Index: lib/rails_generator/generators/components/scaffold_resource/templates/controller.rb
===================================================================
--- lib/rails_generator/generators/components/scaffold_resource/templates/controller.rb	(revision 6337)
+++ lib/rails_generator/generators/components/scaffold_resource/templates/controller.rb	(working copy)
@@ -2,6 +2,10 @@
   # GET /<%= table_name %>
   # GET /<%= table_name %>.xml
   def index
+    assert_request do |r|
+      r.method :get
+    end
+
     @<%= table_name %> = <%= class_name %>.find(:all)
 
     respond_to do |format|
@@ -13,6 +17,11 @@
   # GET /<%= table_name %>/1
   # GET /<%= table_name %>/1.xml
   def show
+    assert_request do |r|
+      r.method :get
+      r.params.must_have :id
+    end
+
     @<%= file_name %> = <%= class_name %>.find(params[:id])
 
     respond_to do |format|
@@ -23,17 +32,29 @@
 
   # GET /<%= table_name %>/new
   def new
+    assert_request do |r|
+      r.method :get
+    end
     @<%= file_name %> = <%= class_name %>.new
   end
 
   # GET /<%= table_name %>/1;edit
   def edit
+    assert_request do |r|
+      r.method :get
+      r.params.must_have :id
+    end
     @<%= file_name %> = <%= class_name %>.find(params[:id])
   end
 
   # POST /<%= table_name %>
   # POST /<%= table_name %>.xml
   def create
+    assert_request do |r|
+      r.method :post
+      r.params.must_have <%= class_name %>
+    end
+
     @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
 
     respond_to do |format|
@@ -51,6 +72,11 @@
   # PUT /<%= table_name %>/1
   # PUT /<%= table_name %>/1.xml
   def update
+    assert_request do |r|
+      r.method :put
+      r.params.must_have :id, <%= class_name %>
+    end
+
     @<%= file_name %> = <%= class_name %>.find(params[:id])
 
     respond_to do |format|
@@ -68,6 +94,11 @@
   # DELETE /<%= table_name %>/1
   # DELETE /<%= table_name %>/1.xml
   def destroy
+    assert_request do |r|
+      r.method :delete
+      r.params.must_have :id
+    end
+
     @<%= file_name %> = <%= class_name %>.find(params[:id])
     @<%= file_name %>.destroy
 
Index: lib/rails_generator/generators/components/scaffold_resource/templates/functional_test.rb
===================================================================
--- lib/rails_generator/generators/components/scaffold_resource/templates/functional_test.rb	(revision 6337)
+++ lib/rails_generator/generators/components/scaffold_resource/templates/functional_test.rb	(working copy)
@@ -26,7 +26,11 @@
   
   def test_should_create_<%= file_name %>
     old_count = <%= class_name %>.count
-    post :create, :<%= file_name %> => { }
+    post :create, :<%= file_name %> => { 
+    <% for attribute in attributes -%>
+      :<%= attribute.name %> => "<%= attribute.default %>"
+    <% end -%>
+    }
     assert_equal old_count+1, <%= class_name %>.count
     
     assert_redirected_to <%= file_name %>_path(assigns(:<%= file_name %>))
@@ -43,7 +47,11 @@
   end
   
   def test_should_update_<%= file_name %>
-    put :update, :id => 1, :<%= file_name %> => { }
+    put :update, :id => 1, :<%= file_name %> => {
+    <% for attribute in attributes -%>
+      :<%= attribute.name %> => "<%= attribute.default %>"
+    <% end -%>
+    }      
     assert_redirected_to <%= file_name %>_path(assigns(:<%= file_name %>))
   end
   
