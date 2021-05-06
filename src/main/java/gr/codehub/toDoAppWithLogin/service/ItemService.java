package gr.codehub.toDoAppWithLogin.service;

import gr.codehub.toDoAppWithLogin.model.Item;
import gr.codehub.toDoAppWithLogin.repository.ItemRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ItemService {

    ItemRepository itemRepository;

    public ItemService(ItemRepository itemRepository) {
        this.itemRepository = itemRepository;
    }

    public List<Item> findAllItems() {
        return itemRepository.findAll();
    }

    public void addItem(String description) {
        itemRepository.save(new Item(description));
    }

    public void deleteItem(long id) {
        itemRepository.deleteById(id);
    }
}
