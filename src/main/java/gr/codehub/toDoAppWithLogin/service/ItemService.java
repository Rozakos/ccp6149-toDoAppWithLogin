package gr.codehub.toDoAppWithLogin.service;

import gr.codehub.toDoAppWithLogin.model.Item;
import gr.codehub.toDoAppWithLogin.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ItemService {

    private final ItemRepository itemRepository;

    public List<Item> findAllItems() {
        return itemRepository.findAll();
    }

    public void addItem(String description) {
        itemRepository.save(Item.builder().description(description).build());
    }

    public void deleteItem(long id) {
        itemRepository.deleteById(id);
    }
}
