module Spec
  module Rails
    module Matchers
      class HaveValidAssociations
        def matches?(model)
          @failed_association = nil
          @model_class = model.class

          model.save(false)
      
          model.class.reflect_on_all_associations.each do |assoc|
            object = model.send(assoc.name, true) rescue @failed_association = assoc.name

            if object.nil?
              model.send(assoc.name, :reset) # does this actually do anything
            else
              begin
                model.send(assoc.name).reload
              rescue => err 
                @failed_association = "#{assoc.name} => #{err.message}"
              end
            end
          end
          !@failed_association
        end
  
        def failure_message
          "invalid association \"#{@failed_association}\" on #{@model_class}"
        end
      end

      def have_valid_associations
        HaveValidAssociations.new
      end
    end
  end
end