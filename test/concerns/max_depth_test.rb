require_relative '../environment'

class MaxDepthTest < ActiveSupport::TestCase
  def test_root_with_max_depth
    AncestryTestDatabase.with_model :max_depth => 3 do |model|
      node1 = model.create!
      node2 = node1.children.create!
      node3 = node2.children.create!
      node4 = node3.children.create!
      node5 = node4.children.create!
      leaf  = node5.children.create!

      assert_equal node1,                        node2.root
      assert_equal node1,                        node3.root
      assert_equal node1,                        node4.root
      assert_equal node2,                        node5.root
      assert_equal node3,                        leaf.root
    end
  end

  def test_root_with_max_depth_reversed
    AncestryTestDatabase.with_model :max_depth => 3 do |model|
      node1 = model.create!
      node2 = model.create!
      node3 = model.create!
      node4 = model.create!
      node5 = model.create!
      leaf  = model.create!

      leaf.parent = node5
      leaf.save!
      node5.parent = node4
      node5.save!
      node4.parent = node3
      node4.save!
      node3.parent = node2
      node3.save!
      node2.parent = node1
      node2.save!

      assert_equal node1,                        node2.reload.root
      assert_equal node1,                        node3.reload.root
      assert_equal node1,                        node4.reload.root
      assert_equal node2,                        node5.reload.root
      assert_equal node3,                        leaf.reload.root
    end
  end

  def test_ancestors_with_max_depth
    AncestryTestDatabase.with_model :max_depth => 3 do |model|
      node1 = model.create!
      node2 = node1.children.create!
      node3 = node2.children.create!
      node4 = node3.children.create!
      node5 = node4.children.create!
      leaf  = node5.children.create!

      assert_equal [node1],                      node2.ancestors
      assert_equal [node1, node2],               node3.ancestors
      assert_equal [node1, node2, node3],        node4.ancestors
      assert_equal [node2, node3, node4],        node5.ancestors
      assert_equal [node3, node4, node5],        leaf.ancestors
    end
  end

  def test_ancestors_with_max_depth_reversed
    AncestryTestDatabase.with_model :max_depth => 3 do |model|
      node1 = model.create!
      node2 = model.create!
      node3 = model.create!
      node4 = model.create!
      node5 = model.create!
      leaf  = model.create!

      leaf.parent = node5
      leaf.save!
      node5.parent = node4
      node5.save!
      node4.parent = node3
      node4.save!
      node3.parent = node2
      node3.save!
      node2.parent = node1
      node2.save!

      assert_equal [node1],                      node2.reload.ancestors
      assert_equal [node1, node2],               node3.reload.ancestors
      assert_equal [node1, node2, node3],        node4.reload.ancestors
      assert_equal [node2, node3, node4],        node5.reload.ancestors
      assert_equal [node3, node4, node5],        leaf.reload.ancestors
    end
  end

  def test_tree_navigation
    AncestryTestDatabase.with_model :max_depth => 2, :depth => 4, :width => 3 do |model, roots|
      roots.each do |lvl0_node, lvl0_children|
        # Ancestors assertions
        assert_equal [], lvl0_node.ancestor_ids
        assert_equal [], lvl0_node.ancestors
        assert_equal [lvl0_node.id], lvl0_node.path_ids
        assert_equal [lvl0_node], lvl0_node.path
        assert_equal 0, lvl0_node.depth
        # Parent assertions
        assert_nil lvl0_node.parent_id
        assert_nil lvl0_node.parent
        refute lvl0_node.parent_id?
        # Root assertions
        assert_equal lvl0_node.id, lvl0_node.root_id
        assert_equal lvl0_node, lvl0_node.root
        assert lvl0_node.is_root?
        # Children assertions
        assert_equal lvl0_children.map(&:first).map(&:id), lvl0_node.child_ids
        assert_equal lvl0_children.map(&:first), lvl0_node.children
        assert lvl0_node.has_children?
        assert !lvl0_node.is_childless?
        # Siblings assertions
        assert_equal roots.map(&:first).map(&:id), lvl0_node.sibling_ids
        assert_equal roots.map(&:first), lvl0_node.siblings
        assert lvl0_node.has_siblings?
        assert !lvl0_node.is_only_child?
        # Descendants assertions
        descendants = model.all.find_all do |node|
          node.ancestor_ids.include? lvl0_node.id
        end
        assert_equal descendants.map(&:id), lvl0_node.descendant_ids
        assert_equal descendants, lvl0_node.descendants
        assert_equal [lvl0_node] + descendants, lvl0_node.subtree

        lvl0_children.each do |lvl1_node, lvl1_children|
          # Ancestors assertions
          assert_equal [lvl0_node.id], lvl1_node.ancestor_ids
          assert_equal [lvl0_node], lvl1_node.ancestors
          assert_equal [lvl0_node.id, lvl1_node.id], lvl1_node.path_ids
          assert_equal [lvl0_node, lvl1_node], lvl1_node.path
          assert_equal 1, lvl1_node.depth
          # Parent assertions
          assert_equal lvl0_node.id, lvl1_node.parent_id
          assert_equal lvl0_node, lvl1_node.parent
          assert lvl1_node.parent_id?
          # Root assertions
          assert_equal lvl0_node.id, lvl1_node.root_id
          assert_equal lvl0_node, lvl1_node.root
          assert !lvl1_node.is_root?
          # Children assertions
          assert_equal lvl1_children.map(&:first).map(&:id), lvl1_node.child_ids
          assert_equal lvl1_children.map(&:first), lvl1_node.children
          assert lvl1_node.has_children?
          assert !lvl1_node.is_childless?
          # Siblings assertions
          assert_equal lvl0_children.map(&:first).map(&:id), lvl1_node.sibling_ids
          assert_equal lvl0_children.map(&:first), lvl1_node.siblings
          assert lvl1_node.has_siblings?
          assert !lvl1_node.is_only_child?
          # Descendants assertions
          descendants = model.all.find_all do |node|
            node.ancestor_ids.include? lvl1_node.id
          end
          assert_equal descendants.map(&:id), lvl1_node.descendant_ids
          assert_equal descendants, lvl1_node.descendants
          assert_equal [lvl1_node] + descendants, lvl1_node.subtree

          lvl1_children.each do |lvl2_node, lvl2_children|
            # Ancestors assertions
            assert_equal [lvl0_node.id, lvl1_node.id], lvl2_node.ancestor_ids
            assert_equal [lvl0_node, lvl1_node], lvl2_node.ancestors
            assert_equal [lvl0_node.id, lvl1_node.id, lvl2_node.id], lvl2_node.path_ids
            assert_equal [lvl0_node, lvl1_node, lvl2_node], lvl2_node.path
            assert_equal 2, lvl2_node.depth
            # Parent assertions
            assert_equal lvl1_node.id, lvl2_node.parent_id
            assert_equal lvl1_node, lvl2_node.parent
            assert lvl2_node.parent_id?
            # Root assertions
            assert_equal lvl0_node.id, lvl2_node.root_id
            assert_equal lvl0_node, lvl2_node.root
            assert !lvl2_node.is_root?
            # Children assertions
            assert lvl2_node.has_children?
            assert !lvl2_node.is_childless?
            # Siblings assertions
            assert_equal lvl1_children.map(&:first).map(&:id), lvl2_node.sibling_ids
            assert_equal lvl1_children.map(&:first), lvl2_node.siblings
            assert lvl2_node.has_siblings?
            assert !lvl2_node.is_only_child?
            # Descendants assertions
            descendants = model.all.find_all do |node|
              node.ancestor_ids.include? lvl2_node.id
            end
            assert_equal descendants.map(&:id), lvl2_node.descendant_ids
            assert_equal descendants, lvl2_node.descendants
            assert_equal [lvl2_node] + descendants, lvl2_node.subtree

            lvl2_children.each do |lvl3_node, lvl3_children|
              # Ancestors assertions
              assert_equal [lvl1_node.id, lvl2_node.id], lvl3_node.ancestor_ids
              assert_equal [lvl1_node, lvl2_node], lvl3_node.ancestors
              assert_equal [lvl1_node.id, lvl2_node.id, lvl3_node.id], lvl3_node.path_ids
              assert_equal [lvl1_node, lvl2_node, lvl3_node], lvl3_node.path
              assert_equal 2, lvl3_node.depth
              # Parent assertions
              assert_equal lvl2_node.id, lvl3_node.parent_id
              assert_equal lvl2_node, lvl3_node.parent
              assert lvl3_node.parent_id?
              # Root assertions
              assert_equal lvl1_node.id, lvl3_node.root_id
              assert_equal lvl1_node, lvl3_node.root
              assert !lvl3_node.is_root?
              # Children assertions
              assert_equal [], lvl3_node.child_ids
              assert_equal [], lvl3_node.children
              assert !lvl3_node.has_children?
              assert lvl3_node.is_childless?
              # Siblings assertions
              assert_equal lvl2_children.map(&:first).map(&:id), lvl3_node.sibling_ids
              assert_equal lvl2_children.map(&:first), lvl3_node.siblings
              assert lvl3_node.has_siblings?
              assert !lvl3_node.is_only_child?
              # Descendants assertions
              descendants = model.all.find_all do |node|
                node.ancestor_ids.include? lvl3_node.id
              end
              assert_equal descendants.map(&:id), lvl3_node.descendant_ids
              assert_equal descendants, lvl3_node.descendants
              assert_equal [lvl3_node] + descendants, lvl3_node.subtree
            end
          end
        end
      end
    end
  end
end