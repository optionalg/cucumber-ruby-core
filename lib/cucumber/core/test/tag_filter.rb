module Cucumber
  module Core
    module Test

      class TagFilter
        include Cucumber.initializer(:filter_expressions, :receiver)

        def test_case(test_case)
          if test_case.match_tags?(filter_expressions)
            test_case.describe_to(receiver)
          end
          self
        end
      end

    end
  end
end
